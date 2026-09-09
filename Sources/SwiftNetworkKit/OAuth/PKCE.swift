import Foundation

#if canImport(CryptoKit)
import CryptoKit
#endif
#if canImport(Security)
import Security
#endif

/// A PKCE (RFC 7636) verifier/challenge pair. Create one per authorization request, keep it until the
/// redirect comes back, then pass it to ``AuthorizationCodeFlow/exchange(code:pkce:)``.
public struct PKCE: Sendable, Hashable {

    /// 43 characters of `[A-Za-z0-9-._~]` from 32 cryptographically-random bytes (base64url).
    public let verifier: String

    /// `base64url(SHA256(verifier))`.
    public let challenge: String

    /// Always `"S256"` — the only method this package emits.
    public let method = "S256"

    public init() {
        self.init(verifier: PKCE.randomVerifier())
    }

    /// Testing hook: build the pair from a known verifier (e.g. an RFC 7636 test vector).
    public init(verifier: String) {
        self.verifier = verifier
        self.challenge = PKCE.challenge(for: verifier)
    }

    static func challenge(for verifier: String) -> String {
        let digest = Data(verifier.utf8).sha256()
        return Base64URL.encode(digest)
    }

    private static func randomVerifier() -> String {
        var bytes = [UInt8](repeating: 0, count: 32)
        #if canImport(Security)
        if SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes) != errSecSuccess {
            bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        }
        #else
        bytes = (0..<32).map { _ in UInt8.random(in: .min ... .max) }
        #endif
        return Base64URL.encode(Data(bytes))
    }
}

extension Data {
    fileprivate func sha256() -> Data {
        #if canImport(CryptoKit)
        return Data(SHA256.hash(data: self))
        #else
        return SHA256Fallback.hash(self)
        #endif
    }
}
