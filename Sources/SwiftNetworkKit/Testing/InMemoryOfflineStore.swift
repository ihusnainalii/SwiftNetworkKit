import Foundation

/// An ``OfflineStore`` that keeps the queue in memory. Shipped for tests and previews.
@_spi(SwiftNetworkKitTesting) public actor InMemoryOfflineStore: OfflineStore {

    private var queue: [PersistedRequest]

    @_spi(SwiftNetworkKitTesting) public init(seed: [PersistedRequest] = []) {
        self.queue = seed
    }

    @_spi(SwiftNetworkKitTesting) public func append(_ request: PersistedRequest) { queue.append(request) }
    @_spi(SwiftNetworkKitTesting) public func all() -> [PersistedRequest] { queue }
    @_spi(SwiftNetworkKitTesting) public func remove(_ id: RequestID) { queue.removeAll { $0.id == id } }
    @_spi(SwiftNetworkKitTesting) public func removeAll() { queue.removeAll() }

    @_spi(SwiftNetworkKitTesting) public func update(_ request: PersistedRequest) {
        guard let index = queue.firstIndex(where: { $0.id == request.id }) else { return }
        queue[index] = request
    }

    @_spi(SwiftNetworkKitTesting) public var count: Int { queue.count }
}
