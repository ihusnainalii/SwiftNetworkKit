import Foundation

/// The kind of link a satisfied network path is using.
public enum ConnectionType: Sendable, Hashable {
    case wifi
    case cellular
    case wiredEthernet
    /// Loopback, VPN with an unknown underlying interface, or anything else.
    case other
}
