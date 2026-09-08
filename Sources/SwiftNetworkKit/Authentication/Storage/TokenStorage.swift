import Foundation

/// Pluggable secure storage for tokens and related secrets.
///
/// Implement the three data primitives; ``TokenPair`` accessors are provided as extensions that
/// serialize to a reserved key. Ships ``InMemoryTokenStorage`` and (on Apple platforms)
/// ``KeychainTokenStorage``.
public protocol TokenStorage: Sendable {
    /// Raw bytes for a key, or `nil` if absent.
    func data(forKey key: String) async throws -> Data?
    /// Stores (or, with `nil`, removes) bytes for a key.
    func setData(_ data: Data?, forKey key: String) async throws
    /// Removes everything this storage owns.
    func removeAll() async throws
}

extension TokenStorage {
    /// Reserved key under which the ``TokenPair`` is persisted.
    public static var tokenPairKey: String { "com.swiftnetworkkit.auth.tokenPair" }

    public func currentTokenPair() async throws -> TokenPair? {
        guard let data = try await data(forKey: Self.tokenPairKey) else { return nil }
        return try JSONDecoder().decode(TokenPair.self, from: data)
    }

    public func store(_ pair: TokenPair) async throws {
        try await setData(try JSONEncoder().encode(pair), forKey: Self.tokenPairKey)
    }

    public func accessToken() async throws -> String? {
        try await currentTokenPair()?.accessToken
    }

    public func refreshToken() async throws -> String? {
        try await currentTokenPair()?.refreshToken
    }

    /// Removes just the token pair (leaves other stored values in place).
    public func clearTokenPair() async throws {
        try await setData(nil, forKey: Self.tokenPairKey)
    }
}
