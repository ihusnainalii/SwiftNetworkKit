import Foundation

/// Thrown by ``NetworkClient/validated(configuration:transport:refresh:onSessionExpired:)`` instead of
/// trapping, for the handful of `NetworkClient(configuration:...)` failure modes that are a runtime or
/// build-environment problem rather than a programmer typo: a bundled pinning resource missing from a
/// downstream build, or (on WebAssembly) no transport supplied where there is no default one.
public enum NetworkClientInitializationError: Error, Sendable {
    /// `configuration.sslPinning` could not be resolved into pins. See the wrapped ``SSLPinningError``.
    case invalidPinningConfiguration(SSLPinningError)
    /// No `transport:` was supplied on a platform (WebAssembly) with no default `URLSession`-based one.
    case transportRequired
}
