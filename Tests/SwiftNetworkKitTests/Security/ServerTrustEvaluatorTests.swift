#if canImport(Security)
import Foundation
import Security
import Testing

@testable import SwiftNetworkKit

@Suite("ServerTrustEvaluator")
struct ServerTrustEvaluatorTests {

    private func evaluator(
        _ config: SSLPinningConfiguration, log: @escaping @Sendable (String) -> Void = { _ in }
    ) -> ServerTrustEvaluator {
        ServerTrustEvaluator(configuration: config, log: log)
    }

    @Test("computed SPKI hash matches openssl for RSA and EC fixtures")
    func spkiMatchesOpenSSL() throws {
        let rsa = try PinningFixtures.spkiSHA256Base64("pinning-rsa")
        #expect(rsa == PinningFixtures.rsaSPKISHA256)
        let ec = try PinningFixtures.spkiSHA256Base64("pinning-ec")
        #expect(ec == PinningFixtures.ecSPKISHA256)
    }

    @Test("matching public-key pin is .pinned")
    func publicKeyMatch() throws {
        let pin = Pin.publicKeySHA256(Data(base64Encoded: PinningFixtures.rsaSPKISHA256)!)
        let config = SSLPinningConfiguration(pins: [PinningFixtures.rsaHost: [pin]])
        let result = evaluator(config).evaluate(
            trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result == .pinned)
    }

    @Test("wrong pin is .rejected(.sslPinningFailed)")
    func wrongPin() throws {
        let config = SSLPinningConfiguration(pins: [
            PinningFixtures.rsaHost: [.publicKeySHA256(PinningFixtures.bogusHash)]
        ])
        let result = evaluator(config).evaluate(
            trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.rejectionCode == .sslPinningFailed)
    }

    @Test("unmatched host is .notPinned (defers to system TLS, does not vouch)")
    func unmatchedHost() throws {
        let config = SSLPinningConfiguration(pins: ["other.example.com": [.publicKeySHA256(PinningFixtures.bogusHash)]])
        let result = evaluator(config).evaluate(
            trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result == .notPinned)
    }

    @Test("rotation: any pin in the list may match")
    func rotation() throws {
        let good = Pin.publicKeySHA256(Data(base64Encoded: PinningFixtures.rsaSPKISHA256)!)
        let config = SSLPinningConfiguration(pins: [
            PinningFixtures.rsaHost: [.publicKeySHA256(PinningFixtures.bogusHash), good]
        ])
        let result = evaluator(config).evaluate(
            trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result == .pinned)
    }

    @Test("certificate (DER) pin is .pinned")
    func certificatePin() throws {
        let config = SSLPinningConfiguration(pins: [
            PinningFixtures.rsaHost: [.certificate(try PinningFixtures.der("pinning-rsa"))]
        ])
        let result = evaluator(config).evaluate(
            trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result == .pinned)
    }

    @Test("EC-P256 fixture pins by public key")
    func ecPublicKey() throws {
        let pin = Pin.publicKeySHA256(Data(base64Encoded: PinningFixtures.ecSPKISHA256)!)
        let config = SSLPinningConfiguration(pins: [PinningFixtures.ecHost: [pin]])
        let result = evaluator(config).evaluate(
            trust: try PinningFixtures.trust(for: "pinning-ec"), host: PinningFixtures.ecHost)
        #expect(result == .pinned)
    }

    @Test("recordOnly logs the computed pin but returns .notPinned (system TLS still applies)")
    func recordOnly() throws {
        let logged = LoggedLines()
        let config = SSLPinningConfiguration(
            pins: [PinningFixtures.rsaHost: [.publicKeySHA256(PinningFixtures.bogusHash)]],
            mode: .recordOnly
        )
        let result = evaluator(config) { logged.append($0) }
            .evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result == .notPinned)
        #expect(logged.all.contains { $0.contains(PinningFixtures.rsaSPKISHA256) })
    }
}

private final class LoggedLines: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []
    func append(_ line: String) { lock.withLock { lines.append(line) } }
    var all: [String] { lock.withLock { lines } }
}

extension ServerTrustDecision {
    fileprivate var rejectionCode: NetworkError.Code? {
        if case .rejected(let e) = self { return e.code } else { return nil }
    }
}
#endif
