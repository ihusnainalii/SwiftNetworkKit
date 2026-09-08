import Foundation

/// Whether a failed pin check blocks the connection.
public enum PinningMode: Sendable, Hashable {
    /// A mismatch fails the request with ``NetworkError/sslPinningFailed(host:)``. Use in production.
    case enforced
    /// Never blocks: the computed `sha256/…` pins are logged and the connection is allowed. Use
    /// during development to discover the values to paste into a `.publicKeys([...])` config.
    case recordOnly
}
