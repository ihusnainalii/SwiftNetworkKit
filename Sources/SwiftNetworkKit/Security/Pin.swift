import Foundation

/// One thing a server's certificate chain can be checked against.
public enum Pin: Sendable, Hashable {
    /// The exact DER bytes of a certificate anywhere in the chain.
    case certificate(Data)
    /// SHA-256 of a certificate's SubjectPublicKeyInfo (32 bytes). Survives certificate renewal as
    /// long as the key pair is kept.
    case publicKeySHA256(Data)
}
