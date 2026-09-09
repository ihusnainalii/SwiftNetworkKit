import Foundation

/// A ``NetworkMonitor`` whose status you drive by hand. Shipped in the library so consuming apps can
/// test their offline behavior too.
@_spi(SwiftNetworkKitTesting) public final class MockNetworkMonitor: NetworkMonitor, @unchecked Sendable {

    private let broadcaster: NetworkStatusBroadcaster

    @_spi(SwiftNetworkKitTesting) public init(initial: NetworkStatus = .requiresConnection) {
        self.broadcaster = NetworkStatusBroadcaster(initial: initial)
    }

    @_spi(SwiftNetworkKitTesting) public var currentStatus: NetworkStatus {
        get async { await broadcaster.current }
    }

    @_spi(SwiftNetworkKitTesting) public func statusUpdates() async -> AsyncStream<NetworkStatus> {
        await broadcaster.stream()
    }

    /// Pushes `status` to every current subscriber and updates ``currentStatus``.
    @_spi(SwiftNetworkKitTesting) public func send(_ status: NetworkStatus) async {
        await broadcaster.publish(status)
    }

    /// Replays a sequence of statuses in order.
    @_spi(SwiftNetworkKitTesting) public func send(_ statuses: [NetworkStatus]) async {
        for status in statuses { await broadcaster.publish(status) }
    }

    /// Ends every subscriber's stream.
    @_spi(SwiftNetworkKitTesting) public func finish() async {
        await broadcaster.finishAll()
    }

    /// How many live subscriptions exist right now.
    @_spi(SwiftNetworkKitTesting) public var subscriberCount: Int {
        get async { await broadcaster.subscriberCount }
    }
}
