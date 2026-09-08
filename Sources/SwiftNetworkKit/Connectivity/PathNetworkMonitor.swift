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

    public init() {
        let broadcaster = broadcaster
        pathMonitor.pathUpdateHandler = { path in
            let status = NetworkStatus(path)
            Task { await broadcaster.publish(status) }
        }
        pathMonitor.start(queue: queue)
    }

    deinit {
        pathMonitor.cancel()
        let broadcaster = broadcaster
        Task { await broadcaster.finishAll() }
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
