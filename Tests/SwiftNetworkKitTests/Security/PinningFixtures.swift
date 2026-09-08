import Foundation
import Security
import Testing
@testable import SwiftNetworkKit

/// Self-signed fixture certificates generated once with openssl (RSA-2048 and EC-P256), plus their
/// true SubjectPublicKeyInfo SHA-256 hashes.
enum PinningFixtures {

    static let rsaHost = "pinning.test.swiftnetworkkit"
    static let ecHost = "ec.pinning.test"

    /// `openssl x509 -pubkey | openssl pkey -pubin -outform DER | openssl dgst -sha256 -binary | base64`
    static let rsaSPKISHA256 = "QUwWYGyKPjXt+g+6Pn0d5bAbk+FyZYMukaMImKMQu5o="
    static let ecSPKISHA256 = "AmL46xr11QRzUS02LKIOdLzbg4METeJqXtRGj7oBpYU="

    static func der(_ name: String) throws -> Data {
        let url = try #require(
            Bundle.module.url(forResource: "Fixtures/\(name)", withExtension: "der"),
            "missing fixture \(name).der"
        )
        return try Data(contentsOf: url)
    }

    static func certificate(_ name: String) throws -> SecCertificate {
        try #require(SecCertificateCreateWithData(nil, try der(name) as CFData))
    }

    /// A `SecTrust` for the fixture cert, trusting it as its own anchor so chain validation passes.
    static func trust(for name: String) throws -> SecTrust {
        let certificate = try certificate(name)
        var trust: SecTrust?
        let status = SecTrustCreateWithCertificates(certificate, SecPolicyCreateBasicX509(), &trust)
        #expect(status == errSecSuccess)
        let unwrapped = try #require(trust)
        SecTrustSetAnchorCertificates(unwrapped, [certificate] as CFArray)
        return unwrapped
    }

    static let bogusHash = Data(repeating: 0xAB, count: 32)

    /// The package's own SPKI-SHA256 for a fixture, base64-encoded (should equal the openssl value).
    static func spkiSHA256Base64(_ name: String) throws -> String {
        let hash = try #require(ServerTrustEvaluator.spkiSHA256(try certificate(name)))
        return hash.base64EncodedString()
    }
}
