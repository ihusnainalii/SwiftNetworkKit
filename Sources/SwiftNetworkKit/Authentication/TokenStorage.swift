import Foundation

/// An access/refresh token pair with an optional expiry.
public struct TokenPair: Sendable, Equatable, Codable {
    public var accessToken: String
    public var refreshToken: String?
    public var expiresAt: Date?

    public init(accessToken: String, refreshToken: String? = nil, expiresAt: Date? = nil) {
        self.accessToken = accessToken
        self.refreshToken = refreshToken
        self.expiresAt = expiresAt
    }

    /// `true` when `expiresAt` is set and within `leeway` seconds of now (or already past).
    public func isExpired(leeway: TimeInterval = 0) -> Bool {
        guard let expiresAt else { return false }
        return expiresAt.timeIntervalSinceNow <= leeway
    }
}

/// Pluggable secure storage for tokens and related secrets.
///
/// Implement the three data primitives; ``TokenPair`` accessors are provided as extensions that
/// serialize to a reserved key. Ships ``InMemoryTokenStorage`` and (on Apple platforms)
/// `KeychainTokenStorage`.
public protocol TokenStorage: Sendable {
    /// Raw bytes for a key, or `nil` if absent.
    func data(forKey key: String) async throws -> Data?
    /// Stores (or, with `nil`, removes) bytes for a key.
    func setData(_ data: Data?, forKey key: String) async throws
    /// Removes everything this storage owns.
    func removeAll() async throws
}

public extension TokenStorage {
    /// Reserved key under which the ``TokenPair`` is persisted.
    static var tokenPairKey: String { "com.swiftnetworkkit.auth.tokenPair" }

    func currentTokenPair() async throws -> TokenPair? {
        guard let data = try await data(forKey: Self.tokenPairKey) else { return nil }
        return try JSONDecoder().decode(TokenPair.self, from: data)
    }

    func store(_ pair: TokenPair) async throws {
        try await setData(try JSONEncoder().encode(pair), forKey: Self.tokenPairKey)
    }

    func accessToken() async throws -> String? {
        try await currentTokenPair()?.accessToken
    }

    func refreshToken() async throws -> String? {
        try await currentTokenPair()?.refreshToken
    }

    /// Removes just the token pair (leaves other stored values in place).
    func clearTokenPair() async throws {
        try await setData(nil, forKey: Self.tokenPairKey)
    }
}

/// Non-persistent storage. Good for tests and for apps that intentionally keep tokens in memory only.
public actor InMemoryTokenStorage: TokenStorage {
    private var storage: [String: Data]

    public init() {
        storage = [:]
    }

    /// Seeds the storage with an initial token pair.
    public init(seed pair: TokenPair) {
        storage = [:]
        if let data = try? JSONEncoder().encode(pair) {
            storage[InMemoryTokenStorage.tokenPairKey] = data
        }
    }

    public func data(forKey key: String) -> Data? {
        storage[key]
    }

    public func setData(_ data: Data?, forKey key: String) {
        storage[key] = data
    }

    public func removeAll() {
        storage.removeAll()
    }
}
