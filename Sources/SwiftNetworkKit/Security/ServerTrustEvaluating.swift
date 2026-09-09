import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

#if canImport(Security)
import Security

/// The port the transport's `URLSession` delegate calls for every server-trust challenge. Pure —
/// no `URLSession`, no I/O — so it is unit-tested against fixture `SecTrust` values.
public protocol ServerTrustEvaluating: Sendable {
    /// - Returns: ``ServerTrustDecision/pinned`` when a pin matched, ``ServerTrustDecision/notPinned``
    ///   when the host is not covered by the configuration (or in record-only mode), and
    ///   ``ServerTrustDecision/rejected(_:)`` when pins are configured for the host and none matched.
    func evaluate(trust: SecTrust, host: String) -> ServerTrustDecision
}
#endif
