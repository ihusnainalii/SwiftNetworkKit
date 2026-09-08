import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("PKCE")
struct PKCETests {

    @Test("challenge matches the RFC 7636 Appendix B test vector")
    func rfcTestVector() {
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        #expect(pkce.challenge == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        #expect(pkce.method == "S256")
    }

    @Test("a generated verifier is 43 unreserved base64url characters")
    func generatedVerifier() {
        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        for _ in 0..<50 {
            let verifier = PKCE().verifier
            #expect(verifier.count == 43)  // 32 bytes -> 43 unpadded base64url chars
            #expect(verifier.unicodeScalars.allSatisfy { allowed.contains($0) })
            #expect(!verifier.contains("="))
        }
    }

    @Test("two PKCE pairs are distinct")
    func uniqueness() {
        #expect(PKCE().verifier != PKCE().verifier)
    }
}
