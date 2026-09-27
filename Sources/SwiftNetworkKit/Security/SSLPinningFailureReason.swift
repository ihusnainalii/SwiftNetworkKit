import Foundation

/// Why a certificate or public-key pin check failed. Diagnostic detail attached to
/// ``NetworkError/sslPinningFailed(host:reason:)``, so a rotation outage or a misconfiguration can be
/// told apart from the error alone, not just from a log line.
public enum SSLPinningFailureReason: Sendable {
    /// The challenge carried no server trust object to evaluate at all.
    case missingServerTrust
    /// The system chain evaluation (`SecTrustEvaluateWithError`) rejected the certificate itself, before
    /// any pin was checked. `underlying` is the `CFError` Security reported, when one was available.
    case systemTrustEvaluationFailed(underlying: (any Error & Sendable)?)
    /// The chain validated, but none of the configured pins matched what the server presented.
    /// `presentedSPKIHashes` are the SPKI SHA-256 hashes (`sha256/<base64>`) the server's chain actually
    /// carried, so a certificate rotation can be diagnosed and fixed from the error alone.
    case noPinMatched(presentedSPKIHashes: [String])
    /// No further detail is available. The default for a pinning failure constructed without one.
    case unspecified
}
