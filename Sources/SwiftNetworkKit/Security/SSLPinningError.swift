import Foundation

/// Why a ``SSLPinning`` value could not be resolved into pins. Surfaces at `NetworkClient` init —
/// a misconfigured pin set must fail loudly, never silently degrade to no pinning.
public enum SSLPinningError: Error, Sendable, Equatable {
    /// A named certificate resource was not in the bundle.
    case resourceNotFound(name: String, extension: String, bundle: String)
    /// A certificate file's bytes were not a valid DER certificate.
    case invalidCertificate(source: String)
    /// A `.publicKeys` entry was not valid base64 (optionally `sha256/`-prefixed) of 32 bytes.
    case invalidPublicKeyHash(String)
    /// No host could be determined for a pin set (empty `hosts:` and no usable base URL).
    case noHostForPins
}
