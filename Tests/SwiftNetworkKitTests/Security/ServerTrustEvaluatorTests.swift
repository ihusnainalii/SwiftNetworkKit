import Foundation
import Security
import Testing
@testable import SwiftNetworkKit

@Suite("ServerTrustEvaluator")
struct ServerTrustEvaluatorTests {

    private func evaluator(_ config: SSLPinningConfiguration, log: @escaping @Sendable (String) -> Void = { _ in }) -> ServerTrustEvaluator {
        ServerTrustEvaluator(configuration: config, log: log)
    }

    @Test("computed SPKI hash matches openssl for RSA and EC fixtures")
    func spkiMatchesOpenSSL() throws {
        let rsa = try PinningFixtures.spkiSHA256Base64("pinning-rsa")
        #expect(rsa == PinningFixtures.rsaSPKISHA256)
        let ec = try PinningFixtures.spkiSHA256Base64("pinning-ec")
        #expect(ec == PinningFixtures.ecSPKISHA256)
    }

    @Test("matching public-key pin passes")
    func publicKeyMatch() throws {
        let pin = Pin.publicKeySHA256(Data(base64Encoded: PinningFixtures.rsaSPKISHA256)!)
        let config = SSLPinningConfiguration(pins: [PinningFixtures.rsaHost: [pin]])
        let result = evaluator(config).evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.isSuccess)
    }

    @Test("wrong pin fails with .sslPinningFailed")
    func wrongPin() throws {
        let config = SSLPinningConfiguration(pins: [PinningFixtures.rsaHost: [.publicKeySHA256(PinningFixtures.bogusHash)]])
        let result = evaluator(config).evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.failureCode == .sslPinningFailed)
    }

    @Test("unmatched host is not pinned (passes)")
    func unmatchedHost() throws {
        let config = SSLPinningConfiguration(pins: ["other.example.com": [.publicKeySHA256(PinningFixtures.bogusHash)]])
        let result = evaluator(config).evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.isSuccess)
    }

    @Test("rotation: any pin in the list may match")
    func rotation() throws {
        let good = Pin.publicKeySHA256(Data(base64Encoded: PinningFixtures.rsaSPKISHA256)!)
        let config = SSLPinningConfiguration(pins: [PinningFixtures.rsaHost: [.publicKeySHA256(PinningFixtures.bogusHash), good]])
        let result = evaluator(config).evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.isSuccess)
    }

    @Test("certificate (DER) pin passes")
    func certificatePin() throws {
        let config = SSLPinningConfiguration(pins: [PinningFixtures.rsaHost: [.certificate(try PinningFixtures.der("pinning-rsa"))]])
        let result = evaluator(config).evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.isSuccess)
    }

    @Test("EC-P256 fixture pins by public key")
    func ecPublicKey() throws {
        let pin = Pin.publicKeySHA256(Data(base64Encoded: PinningFixtures.ecSPKISHA256)!)
        let config = SSLPinningConfiguration(pins: [PinningFixtures.ecHost: [pin]])
        let result = evaluator(config).evaluate(trust: try PinningFixtures.trust(for: "pinning-ec"), host: PinningFixtures.ecHost)
        #expect(result.isSuccess)
    }

    @Test("recordOnly never blocks and logs the computed pin")
    func recordOnly() throws {
        let logged = LoggedLines()
        let config = SSLPinningConfiguration(
            pins: [PinningFixtures.rsaHost: [.publicKeySHA256(PinningFixtures.bogusHash)]],
            mode: .recordOnly
        )
        let result = evaluator(config) { logged.append($0) }
            .evaluate(trust: try PinningFixtures.trust(for: "pinning-rsa"), host: PinningFixtures.rsaHost)
        #expect(result.isSuccess)
        #expect(logged.all.contains { $0.contains(PinningFixtures.rsaSPKISHA256) })
    }
}

private final class LoggedLines: @unchecked Sendable {
    private let lock = NSLock()
    private var lines: [String] = []
    func append(_ line: String) { lock.withLock { lines.append(line) } }
    var all: [String] { lock.withLock { lines } }
}

private extension Result where Success == Void, Failure == NetworkError {
    var isSuccess: Bool { if case .success = self { return true } else { return false } }
    var failureCode: NetworkError.Code? { if case .failure(let e) = self { return e.code } else { return nil } }
}
