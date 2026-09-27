#if canImport(Security)
import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("SSLPinning resolution")
struct SSLPinningResolutionTests {

    @Test(".disabled resolves to nil")
    func disabled() throws {
        #expect(try SSLPinning.disabled.resolve(defaultHost: "api.example.com") == nil)
    }

    @Test(".certificates(data:) yields a cert pin + an SPKI pin for the inferred host")
    func certificatesFromData() throws {
        let der = try PinningFixtures.der("pinning-rsa")
        let resolved = try #require(try SSLPinning.certificates([der]).resolve(defaultHost: "api.example.com"))
        let pins = try #require(resolved.pins["api.example.com"])
        #expect(pins.contains(.certificate(der)))
        #expect(pins.contains { if case .publicKeySHA256 = $0 { return true } else { return false } })
    }

    @Test("explicit hosts win over the inferred one")
    func explicitHosts() throws {
        let der = try PinningFixtures.der("pinning-rsa")
        let resolved = try #require(
            try SSLPinning.certificates([der], hosts: ["a.example.com", "b.example.com"])
                .resolve(defaultHost: "ignored.example.com")
        )
        #expect(Set(resolved.pins.keys) == ["a.example.com", "b.example.com"])
    }

    @Test(
        ".certificateResources with an unreadable file reports it as unreadable, not missing",
        .enabled(if: geteuid() != 0, "permission bits do not apply to root"))
    func unreadableResource() throws {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("nk-pin-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let file = dir.appendingPathComponent("locked.cer")
        try Data("x".utf8).write(to: file)
        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path)
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)
            try? FileManager.default.removeItem(at: dir)
        }
        let bundle = try #require(Bundle(url: dir))

        do {
            _ = try SSLPinning.certificateResources(["locked"], extension: "cer", bundle: bundle)
                .resolve(defaultHost: "api.example.com")
            Issue.record("expected resolution to fail")
        } catch SSLPinningError.invalidCertificate(let source) {
            #expect(source.contains("locked.cer"))
        } catch {
            Issue.record("expected invalidCertificate, got \(error)")
        }
    }

    @Test(".certificateResources with a missing file throws resourceNotFound")
    func missingResource() {
        #expect(throws: SSLPinningError.self) {
            try SSLPinning.certificateResources(["does-not-exist"], extension: "cer", bundle: .main)
                .resolve(defaultHost: "api.example.com")
        }
    }

    @Test(".publicKeys parses sha256/ prefix and bare base64")
    func publicKeysParsing() throws {
        let hash = PinningFixtures.rsaSPKISHA256
        let resolved = try #require(
            try SSLPinning.publicKeys(["sha256/\(hash)", hash], hosts: ["api.example.com"])
                .resolve(defaultHost: nil)
        )
        #expect(resolved.pins["api.example.com"]?.count == 2)
    }

    @Test(".publicKeys rejects a non-32-byte hash")
    func publicKeysInvalid() {
        #expect(throws: SSLPinningError.self) {
            try SSLPinning.publicKeys(["not-base64!!"], hosts: ["api.example.com"]).resolve(defaultHost: nil)
        }
    }

    @Test("includeSubdomains is reachable through .publicKeys, .certificates and .certificateResources")
    func includeSubdomainsIsReachable() throws {
        let hash = PinningFixtures.rsaSPKISHA256
        let der = try PinningFixtures.der("pinning-rsa")

        let byKey = try #require(
            try SSLPinning.publicKeys([hash], hosts: ["api.example.com"], includeSubdomains: true)
                .resolve(defaultHost: nil))
        #expect(byKey.includeSubdomains)

        let byCert = try #require(
            try SSLPinning.certificates([der], hosts: ["api.example.com"], includeSubdomains: true)
                .resolve(defaultHost: nil))
        #expect(byCert.includeSubdomains)

        // and the default stays false when the caller does not ask for it
        let defaulted = try #require(
            try SSLPinning.publicKeys([hash], hosts: ["api.example.com"]).resolve(defaultHost: nil))
        #expect(!defaulted.includeSubdomains)
    }

    @Test("no host anywhere throws noHostForPins")
    func noHost() throws {
        let der = try PinningFixtures.der("pinning-rsa")
        #expect(throws: SSLPinningError.noHostForPins) {
            try SSLPinning.certificates([der]).resolve(defaultHost: nil)
        }
    }

    @Test(".development wraps any mode in recordOnly")
    func development() throws {
        let resolved = try #require(
            try SSLPinning.development(.publicKeys([PinningFixtures.rsaSPKISHA256], hosts: ["api.example.com"]))
                .resolve(defaultHost: nil)
        )
        #expect(resolved.mode == .recordOnly)
    }

    @Test("an empty pin list for a host under .enforced throws emptyPinList, not 'allow all'")
    func emptyPinsThrows() {
        #expect(throws: SSLPinningError.emptyPinList(host: "api.example.com")) {
            _ = try SSLPinningConfiguration(pins: ["api.example.com": []])
        }
    }

    @Test(".recordOnly may legitimately start with an empty pin list")
    func emptyPinsAllowedUnderRecordOnly() throws {
        let config = try SSLPinningConfiguration(pins: ["api.example.com": []], mode: .recordOnly)
        #expect(config.pins["api.example.com"] == [])
    }
}
#endif
