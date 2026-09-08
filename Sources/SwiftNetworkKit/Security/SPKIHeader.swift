import Foundation
#if canImport(Security)
import Security

/// The ASN.1 SubjectPublicKeyInfo prefix for a given key type/size.
///
/// `SecKeyCopyExternalRepresentation` returns a *bare* key (PKCS#1 for RSA, `04‖X‖Y` for EC). To get
/// the same bytes an X.509 SPKI hash is computed over, the matching header is prepended before
/// hashing. Four common types are supported; anything else is unpinnable via public-key pins.
enum SPKIHeader {

    static let rsa2048: [UInt8] = [
        0x30, 0x82, 0x01, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x01, 0x0f, 0x00,
    ]
    static let rsa4096: [UInt8] = [
        0x30, 0x82, 0x02, 0x22, 0x30, 0x0d, 0x06, 0x09, 0x2a, 0x86, 0x48, 0x86,
        0xf7, 0x0d, 0x01, 0x01, 0x01, 0x05, 0x00, 0x03, 0x82, 0x02, 0x0f, 0x00,
    ]
    static let ecP256: [UInt8] = [
        0x30, 0x59, 0x30, 0x13, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x08, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x03, 0x01, 0x07, 0x03,
        0x42, 0x00,
    ]
    static let ecP384: [UInt8] = [
        0x30, 0x76, 0x30, 0x10, 0x06, 0x07, 0x2a, 0x86, 0x48, 0xce, 0x3d, 0x02,
        0x01, 0x06, 0x05, 0x2b, 0x81, 0x04, 0x00, 0x22, 0x03, 0x62, 0x00,
    ]

    /// The header for `key`'s type and bit size, or `nil` if the type is not supported.
    static func header(for key: SecKey) -> Data? {
        guard let attributes = SecKeyCopyAttributes(key) as? [CFString: Any],
              let keyType = attributes[kSecAttrKeyType] as? String,
              let keySize = attributes[kSecAttrKeySizeInBits] as? Int
        else { return nil }

        let rsa = kSecAttrKeyTypeRSA as String
        let ec = kSecAttrKeyTypeECSECPrimeRandom as String

        switch (keyType, keySize) {
        case (rsa, 2048): return Data(rsa2048)
        case (rsa, 4096): return Data(rsa4096)
        case (ec, 256): return Data(ecP256)
        case (ec, 384): return Data(ecP384)
        default: return nil
        }
    }
}
#endif
