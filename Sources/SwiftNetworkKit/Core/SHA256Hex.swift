import Foundation

#if canImport(CryptoKit)
import CryptoKit
#endif

/// Lower-case hex SHA-256. Fingerprints secrets (an `Authorization` value) and long keys so the
/// original is never embedded in a cache key, a dedup key or a file name.
enum SHA256Hex {

    static func string(_ input: String) -> String {
        let bytes = Data(input.utf8)
        #if canImport(CryptoKit)
        let digest = Data(SHA256.hash(data: bytes))
        #else
        let digest = SHA256Fallback.hash(bytes)
        #endif
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
