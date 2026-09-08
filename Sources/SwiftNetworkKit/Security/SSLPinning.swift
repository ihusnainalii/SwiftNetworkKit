import Foundation

/// The one line an app writes to enable pinning. Everything else — loading `.cer` files, deriving
/// public-key hashes, the `URLSession` delegate, trust evaluation — is the package's job.
///
/// ```swift
/// var config = NetworkConfiguration(baseURL: "https://api.acme.com")
/// config.sslPinning = .certificates(resources: ["acme-2025", "acme-2026"])   // rotation-ready
/// ```
///
/// Omit it (or `.disabled`) for normal system TLS. The certificates are the app's, shipped in the
/// app bundle — never in this package.
public enum SSLPinning: Sendable {

    /// Normal system TLS. No delegate installed.
    case disabled

    /// Pin to certificate files already loaded as DER `Data`.
    case certificates(_ certificates: [Data], hosts: [String] = [])

    /// Pin to `.cer`/`.der` resources in a bundle. Missing file -> init fails.
    case certificateResources(_ names: [String], extension: String = "cer", bundle: Bundle = .main, hosts: [String] = [])

    /// Pin to SubjectPublicKeyInfo SHA-256 hashes: `"sha256/<base64>"` or bare base64.
    case publicKeys(_ spkiSHA256: [String], hosts: [String] = [])

    /// Wrap another mode in ``PinningMode/recordOnly``: never blocks, logs the `sha256/…` values to
    /// paste into a production `.publicKeys([...])`.
    indirect case development(SSLPinning)
}

#if canImport(Security)
import Security

public extension SSLPinning {

    /// Resolves to the internal configuration, or `nil` for `.disabled`.
    /// - Parameter defaultHost: host to pin when a case's `hosts:` is empty (the client passes its base URL host).
    func resolve(defaultHost: String?) throws -> SSLPinningConfiguration? {
        try resolve(defaultHost: defaultHost, mode: .enforced)
    }

    private func resolve(defaultHost: String?, mode: PinningMode) throws -> SSLPinningConfiguration? {
        switch self {
        case .disabled:
            return nil

        case .development(let base):
            return try base.resolve(defaultHost: defaultHost, mode: .recordOnly)

        case .certificates(let certificates, let hosts):
            let pins = try certificates.enumerated().flatMap { index, der in
                try Self.pins(forCertificate: der, source: "certificates[\(index)]")
            }
            return SSLPinningConfiguration(pins: try Self.map(pins, to: hosts, defaultHost: defaultHost), mode: mode)

        case .certificateResources(let resources, let ext, let bundle, let hosts):
            let pins = try resources.flatMap { name -> [Pin] in
                guard let url = bundle.url(forResource: name, withExtension: ext),
                      let der = try? Data(contentsOf: url) else {
                    throw SSLPinningError.resourceNotFound(
                        name: name, extension: ext, bundle: bundle.bundleIdentifier ?? bundle.bundlePath
                    )
                }
                return try Self.pins(forCertificate: der, source: "\(name).\(ext)")
            }
            return SSLPinningConfiguration(pins: try Self.map(pins, to: hosts, defaultHost: defaultHost), mode: mode)

        case .publicKeys(let hashes, let hosts):
            let pins = try hashes.map { Pin.publicKeySHA256(try Self.decodeHash($0)) }
            return SSLPinningConfiguration(pins: try Self.map(pins, to: hosts, defaultHost: defaultHost), mode: mode)
        }
    }

    private static func pins(forCertificate der: Data, source: String) throws -> [Pin] {
        guard let certificate = SecCertificateCreateWithData(nil, der as CFData) else {
            throw SSLPinningError.invalidCertificate(source: source)
        }
        var pins: [Pin] = [.certificate(der)]
        if let spki = ServerTrustEvaluator.spkiSHA256(certificate) {
            pins.append(.publicKeySHA256(spki))
        }
        return pins
    }

    private static func decodeHash(_ raw: String) throws -> Data {
        let trimmed = raw.hasPrefix("sha256/") ? String(raw.dropFirst("sha256/".count)) : raw
        guard let data = Data(base64Encoded: trimmed), data.count == 32 else {
            throw SSLPinningError.invalidPublicKeyHash(raw)
        }
        return data
    }

    private static func map(_ pins: [Pin], to hosts: [String], defaultHost: String?) throws -> [String: [Pin]] {
        let targets = hosts.isEmpty ? [defaultHost].compactMap { $0 } : hosts
        guard !targets.isEmpty else { throw SSLPinningError.noHostForPins }
        return Dictionary(uniqueKeysWithValues: targets.map { ($0.lowercased(), pins) })
    }
}
#endif
