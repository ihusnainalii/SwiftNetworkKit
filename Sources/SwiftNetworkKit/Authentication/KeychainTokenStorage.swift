#if canImport(Security)
import Foundation
import Security

/// Keychain accessibility classes, wrapped so the storage type stays `Sendable`
/// (the underlying `CFString` constants are not).
public enum KeychainAccessibility: Sendable {
    case whenUnlocked
    case afterFirstUnlock
    case whenUnlockedThisDeviceOnly
    case afterFirstUnlockThisDeviceOnly

    var cfValue: CFString {
        switch self {
        case .whenUnlocked: kSecAttrAccessibleWhenUnlocked
        case .afterFirstUnlock: kSecAttrAccessibleAfterFirstUnlock
        case .whenUnlockedThisDeviceOnly: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        case .afterFirstUnlockThisDeviceOnly: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        }
    }
}

/// A keychain-backed OSStatus failure.
public struct KeychainError: Error, Sendable, CustomStringConvertible {
    public let status: OSStatus

    public var description: String {
        let message = SecCopyErrorMessageString(status, nil) as String? ?? "unknown"
        return "KeychainError(\(status)): \(message)"
    }
}

/// `TokenStorage` backed by the system keychain (generic-password items keyed by `service` + account).
///
/// The keychain C API is synchronous; the `async` methods here do not actually suspend.
/// `// ponytail: sync keychain calls on the cooperative pool — fine at token volume; move to a
/// dedicated queue only if profiling shows contention.`
public struct KeychainTokenStorage: TokenStorage {
    public let service: String
    public let accessGroup: String?
    public let accessibility: KeychainAccessibility

    public init(
        service: String,
        accessGroup: String? = nil,
        accessibility: KeychainAccessibility = .afterFirstUnlockThisDeviceOnly
    ) {
        self.service = service
        self.accessGroup = accessGroup
        self.accessibility = accessibility
    }

    public func data(forKey key: String) async throws -> Data? {
        var query = baseQuery(account: key)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        switch status {
        case errSecSuccess: return result as? Data
        case errSecItemNotFound: return nil
        default: throw KeychainError(status: status)
        }
    }

    public func setData(_ data: Data?, forKey key: String) async throws {
        guard let data else {
            let status = SecItemDelete(baseQuery(account: key) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw KeychainError(status: status)
            }
            return
        }

        var attributes = baseQuery(account: key)
        attributes[kSecValueData as String] = data
        attributes[kSecAttrAccessible as String] = accessibility.cfValue

        let addStatus = SecItemAdd(attributes as CFDictionary, nil)
        switch addStatus {
        case errSecSuccess:
            return
        case errSecDuplicateItem:
            let updateStatus = SecItemUpdate(
                baseQuery(account: key) as CFDictionary,
                [kSecValueData as String: data] as CFDictionary
            )
            guard updateStatus == errSecSuccess else { throw KeychainError(status: updateStatus) }
        default:
            throw KeychainError(status: addStatus)
        }
    }

    public func removeAll() async throws {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw KeychainError(status: status)
        }
    }

    /// Whether the keychain is usable in the current process (some CI/test hosts have no keychain).
    /// Performs a real add/delete round-trip.
    public static var isAvailable: Bool {
        let probeService = "com.swiftnetworkkit.keychain.probe"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: probeService,
            kSecAttrAccount as String: "probe",
            kSecValueData as String: Data("probe".utf8),
        ]
        SecItemDelete(query as CFDictionary)
        let addStatus = SecItemAdd(query as CFDictionary, nil)
        if addStatus == errSecSuccess {
            SecItemDelete(query as CFDictionary)
            return true
        }
        return false
    }

    private func baseQuery(account: String) -> [String: Any] {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
        ]
        if let accessGroup { query[kSecAttrAccessGroup as String] = accessGroup }
        return query
    }
}
#endif
