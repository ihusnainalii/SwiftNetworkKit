import Foundation

#if canImport(Security)
import Security

/// The port the transport's `URLSession` delegate calls for every server-trust challenge. Pure —
/// no `URLSession`, no I/O — so it is unit-tested against fixture `SecTrust` values.
public protocol ServerTrustEvaluating: Sendable {
    /// - Returns: `.success` when the host is unpinned or a pin matched; `.failure(.sslPinningFailed)`
    ///   otherwise. In ``PinningMode/recordOnly`` always `.success`.
    func evaluate(trust: SecTrust, host: String) -> Result<Void, NetworkError>
}
#endif
