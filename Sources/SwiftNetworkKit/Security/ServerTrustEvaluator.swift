import Foundation
#if canImport(Security)
import Security
#if canImport(CryptoKit)
import CryptoKit
#endif

/// Validates a server's certificate chain against a resolved ``SSLPinningConfiguration``.
public struct ServerTrustEvaluator: ServerTrustEvaluating {

    let configuration: SSLPinningConfiguration
    private let log: @Sendable (String) -> Void

    /// - Parameter log: sink for `recordOnly` output (the client wires this to its logger at `.error`).
    public init(configuration: SSLPinningConfiguration, log: @escaping @Sendable (String) -> Void = { _ in }) {
        self.configuration = configuration
        self.log = log
    }

    public func evaluate(trust: SecTrust, host: String) -> Result<Void, NetworkError> {
        guard let pins = configuration.pins(matching: host) else {
            return .success(()) // pinning does not apply to this host
        }

        let chain = Self.certificates(in: trust)

        if configuration.mode == .recordOnly {
            for hash in chain.compactMap({ Self.spkiSHA256($0) }) {
                log("SSLPinning[recordOnly] \(host): publicKeys([\"sha256/\(hash.base64EncodedString())\"])")
            }
            return .success(())
        }

        if configuration.validateCertificateChain {
            var error: CFError?
            guard SecTrustEvaluateWithError(trust, &error) else {
                return .failure(.sslPinningFailed(host: host))
            }
        }

        for certificate in chain {
            for pin in pins {
                switch pin {
                case .certificate(let der):
                    if SecCertificateCopyData(certificate) as Data == der { return .success(()) }
                case .publicKeySHA256(let expected):
                    if let actual = Self.spkiSHA256(certificate), actual == expected { return .success(()) }
                }
            }
        }
        return .failure(.sslPinningFailed(host: host))
    }

    // MARK: - Chain / SPKI helpers

    static func certificates(in trust: SecTrust) -> [SecCertificate] {
        if #available(iOS 15.0, macOS 12.0, tvOS 15.0, watchOS 8.0, *) {
            return (SecTrustCopyCertificateChain(trust) as? [SecCertificate]) ?? []
        } else {
            let count = SecTrustGetCertificateCount(trust)
            return (0..<count).compactMap { SecTrustGetCertificateAtIndex(trust, $0) }
        }
    }

    /// SHA-256 of `certificate`'s SubjectPublicKeyInfo (bare key + matching ASN.1 header), or `nil`
    /// when the key type is unsupported.
    static func spkiSHA256(_ certificate: SecCertificate) -> Data? {
        guard
            let key = SecCertificateCopyKey(certificate),
            let header = SPKIHeader.header(for: key),
            let rawKey = SecKeyCopyExternalRepresentation(key, nil) as Data?
        else { return nil }
        var spki = header
        spki.append(rawKey)
        #if canImport(CryptoKit)
        return Data(SHA256.hash(data: spki))
        #else
        return nil
        #endif
    }
}
#endif
