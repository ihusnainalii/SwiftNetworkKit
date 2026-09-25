import Foundation

#if canImport(Network)
import Network

/// The default ``NetworkMonitor``: one `NWPathMonitor` on a dedicated queue, fanned out to
/// subscribers. `NWPathMonitor` never calls back synchronously, so ``currentStatus`` reports
/// ``NetworkStatus/requiresConnection`` until the first update.
public final class PathNetworkMonitor: NetworkMonitor, @unchecked Sendable {

    private let broadcaster = NetworkStatusBroadcaster(initial: .requiresConnection)
    private let pathMonitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "digital.ili.SwiftNetworkKit.PathNetworkMonitor")
    private let updates: AsyncStream<NetworkStatus>.Continuation

    public init() {
        let broadcaster = broadcaster
        // Path updates arrive serially, but a separate `Task` per update could reach the broadcaster
        // out of order and leave it reporting "offline" while the device is online. One consumer
        // draining an ordered stream keeps the last update the last one published.
        let (stream, continuation) = AsyncStream<NetworkStatus>.makeStream()
        updates = continuation
        pathMonitor.pathUpdateHandler = { path in
            continuation.yield(NetworkStatus(path))
        }
        Task {
            for await status in stream { await broadcaster.publish(status) }
            await broadcaster.finishAll()
        }
        pathMonitor.start(queue: queue)
    }

    deinit {
        pathMonitor.cancel()
        updates.finish()
    }

    public var currentStatus: NetworkStatus {
        get async { await broadcaster.current }
    }

    public func statusUpdates() async -> AsyncStream<NetworkStatus> {
        await broadcaster.stream()
    }
}

extension NetworkStatus {
    init(_ path: NWPath) {
        switch path.status {
        case .satisfied:
            self = .satisfied(ConnectionType(path))
        case .unsatisfied:
            self = .unsatisfied
        case .requiresConnection:
            self = .requiresConnection
        @unknown default:
            self = .unsatisfied
        }
    }
}

extension ConnectionType {
    init(_ path: NWPath) {
        if path.usesInterfaceType(.wifi) {
            self = .wifi
        } else if path.usesInterfaceType(.cellular) {
            self = .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            self = .wiredEthernet
        } else {
            self = .other
        }
    }
}
#endif
