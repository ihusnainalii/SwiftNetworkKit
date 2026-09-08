import Foundation

/// An ``OfflineStore`` that keeps the queue in memory. Shipped for tests and previews.
public actor InMemoryOfflineStore: OfflineStore {

    private var queue: [PersistedRequest]

    public init(seed: [PersistedRequest] = []) {
        self.queue = seed
    }

    public func append(_ request: PersistedRequest) { queue.append(request) }
    public func all() -> [PersistedRequest] { queue }
    public func remove(_ id: RequestID) { queue.removeAll { $0.id == id } }
    public func removeAll() { queue.removeAll() }

    public func update(_ request: PersistedRequest) {
        guard let index = queue.firstIndex(where: { $0.id == request.id }) else { return }
        queue[index] = request
    }

    public var count: Int { queue.count }
}
