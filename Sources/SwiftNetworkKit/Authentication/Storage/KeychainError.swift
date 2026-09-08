#if canImport(Security)
import Foundation
import Security

/// A keychain-backed OSStatus failure.
public struct KeychainError: Error, Sendable, CustomStringConvertible {
    public let status: OSStatus

    public var description: String {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
        return "KeychainError(\(status)): \(message)"
    }
}
#endif
