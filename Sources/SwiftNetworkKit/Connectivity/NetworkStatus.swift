import Foundation

/// A snapshot of connectivity, mirroring `NWPath.Status`.
public enum NetworkStatus: Sendable, Hashable {
    /// The path is usable; `ConnectionType` says over what.
    case satisfied(ConnectionType)
    /// No usable path.
    case unsatisfied
    /// A connection is possible but not yet established (e.g. VPN on demand, cellular that needs to
    /// wake). The seed value before `NWPathMonitor`'s first callback.
    case requiresConnection

    /// `true` only for `.satisfied`.
    public var isOnline: Bool {
        if case .satisfied = self { return true }
        return false
    }

    /// The link type when online, else `nil`.
    public var connectionType: ConnectionType? {
        if case .satisfied(let type) = self { return type }
        return nil
    }
}
