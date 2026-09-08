import Foundation

/// Fan-out of `NetworkStatus` to any number of `AsyncStream` subscribers, with last-known replay.
/// Shared by ``PathNetworkMonitor`` and `MockNetworkMonitor`.
actor NetworkStatusBroadcaster {

    private var continuations: [UUID: AsyncStream<NetworkStatus>.Continuation] = [:]
    private(set) var current: NetworkStatus

    init(initial: NetworkStatus) {
        self.current = initial
    }

    /// A new subscription. Immediately yields ``current``, then every later ``publish(_:)``.
    func stream() -> AsyncStream<NetworkStatus> {
        let id = UUID()
        var escaped: AsyncStream<NetworkStatus>.Continuation!
        let stream = AsyncStream<NetworkStatus> { escaped = $0 }
        let continuation = escaped!

        continuations[id] = continuation
        continuation.yield(current)
        continuation.onTermination = { [weak self] _ in
            Task { await self?.remove(id) }
        }
        return stream
    }

    func publish(_ status: NetworkStatus) {
        current = status
        for continuation in continuations.values {
            continuation.yield(status)
        }
    }

    func finishAll() {
        for continuation in continuations.values { continuation.finish() }
        continuations.removeAll()
    }

    var subscriberCount: Int { continuations.count }

    private func remove(_ id: UUID) {
        continuations[id] = nil
    }
}
