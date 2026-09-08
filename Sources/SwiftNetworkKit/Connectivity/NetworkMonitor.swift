import Foundation

/// Connectivity state plus a live stream of changes. Default implementation: ``PathNetworkMonitor``.
/// Tests: `MockNetworkMonitor`.
public protocol NetworkMonitor: Sendable {
    /// The last-known status. `.requiresConnection` until the first real update arrives.
    var currentStatus: NetworkStatus { get async }

    /// A stream that immediately yields the current status, then every change. Each call is an
    /// independent subscription; ending iteration (or cancelling the surrounding task) unsubscribes.
    func statusUpdates() async -> AsyncStream<NetworkStatus>
}

public extension NetworkMonitor {

    /// Yields once every time connectivity returns after having been lost. Handy for draining an
    /// offline queue.
    func connectionRestored() async -> AsyncStream<Void> {
        let updates = await statusUpdates()
        return AsyncStream { continuation in
            let task = Task {
                var wasOffline = false
                for await status in updates {
                    if status.isOnline, wasOffline { continuation.yield(()) }
                    wasOffline = !status.isOnline
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
