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

    // Exit tests (`#expect(processExitsWith:)`) require Swift 6.2+. On older toolchains the
    // precondition in `SSLPinningConfiguration.init` still stands; it just is not asserted here.
    #if compiler(>=6.2)
    @Test("SSLPinningConfiguration traps on an empty pin list for a host")
    func emptyPinsIsProgrammerError() async {
        await #expect(processExitsWith: .failure) {
            _ = SSLPinningConfiguration(pins: ["api.example.com": []])
        }
    }
    #endif
}
