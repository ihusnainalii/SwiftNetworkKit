import Foundation

/// Persists requests made while offline and replays them FIFO when connectivity returns.
///
/// Replayed requests have **no caller awaiting** — the outcome is delivered only on ``events()``.
public actor OfflineRequestQueue {

    public typealias Send = @Sendable (URLRequest) async throws -> HTTPURLResponse

    private let store: any OfflineStore
    private let send: Send
    private let metrics: any NetworkMetrics

    private var subscribers: [UUID: AsyncStream<OfflineReplayEvent>.Continuation] = [:]
    private var monitorTask: Task<Void, Never>?
    private var replaying = false

    public init(
        store: any OfflineStore,
        monitor: any NetworkMonitor,
        metrics: any NetworkMetrics = NoopMetrics(),
        send: @escaping Send
    ) {
        self.store = store
        self.send = send
        self.metrics = metrics
        self.monitorTask = nil
        Task { await self.beginWatching(monitor) }
    }

    deinit { monitorTask?.cancel() }

    private func beginWatching(_ monitor: any NetworkMonitor) {
        guard monitorTask == nil else { return }
        monitorTask = Task { [weak self] in
            for await status in await monitor.statusUpdates() {
                if status.isOnline { await self?.replayNow() }
            }
        }
    }

    /// Archives `request` and adds it to the queue. Returns its id.
    public func enqueue(_ request: URLRequest, expiresAfter: TimeInterval?) async throws -> RequestID {
        guard let archived = URLRequestArchive.archive(request) else {
            throw NetworkError.encoding(underlying: OfflineQueueError.notArchivable)
        }
        let persisted = PersistedRequest(
            urlRequestData: archived,
            expiresAt: expiresAfter.map { Date().addingTimeInterval($0) }
        )
        await store.append(persisted)
        return persisted.id
    }

    /// A stream of replay outcomes. Each call is an independent subscription.
    public func events() -> AsyncStream<OfflineReplayEvent> {
        let id = UUID()
        var escaped: AsyncStream<OfflineReplayEvent>.Continuation!
        let stream = AsyncStream<OfflineReplayEvent> { escaped = $0 }
        subscribers[id] = escaped
        escaped.onTermination = { [weak self] _ in Task { await self?.removeSubscriber(id) } }
        return stream
    }

    /// Number of requests currently queued.
    public var pendingCount: Int {
        get async { await store.all().count }
    }

    /// Replays the queue now (also runs automatically when the monitor reports connectivity).
    public func replayNow() async {
        guard !replaying else { return }
        replaying = true
        defer { replaying = false }

        for var persisted in await store.all() {
            if persisted.isExpired {
                await store.remove(persisted.id)
                emit(.expired(persisted.id))
                continue
            }
            guard let request = URLRequestArchive.unarchive(persisted.urlRequestData) else {
                await store.remove(persisted.id)
                continue
            }
            do {
                let response = try await send(request)
                await store.remove(persisted.id)
                await metrics.record(.success(persisted.id, duration: .zero, status: response.statusCode))
                emit(.replayed(persisted.id, statusCode: response.statusCode))
            } catch {
                persisted.attempts += 1
                await store.update(persisted)
                let mapped = NetworkError.normalize(error)
                await metrics.record(.failure(persisted.id, mapped, status: mapped.statusCode))
                emit(.failed(persisted.id, mapped))
            }
        }
    }

    // MARK: - Internals

    private func emit(_ event: OfflineReplayEvent) {
        for continuation in subscribers.values { continuation.yield(event) }
    }

    private func removeSubscriber(_ id: UUID) {
        subscribers[id] = nil
    }
}

enum OfflineQueueError: Error, Sendable {
    case notArchivable
}
