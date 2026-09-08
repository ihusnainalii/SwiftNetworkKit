import Foundation

public extension TokenPair {
    /// Maps an ``OAuthTokenResponse`` into the pair ``TokenManager`` stores (carrying the absolute
    /// expiry so proactive refresh works).
    init(oauth response: OAuthTokenResponse) {
        self.init(
            accessToken: response.accessToken,
            refreshToken: response.refreshToken,
            expiresAt: response.expiryDate
        )
    }
}

public extension AuthorizationCodeFlow {
    /// A ``TokenManager`` refresh handler backed by this flow. Wire it into `NetworkClient(refresh:)`:
    ///
    /// ```swift
    /// let client = NetworkClient(configuration: config, refresh: flow.tokenManagerRefreshHandler())
    /// ```
    ///
    /// It reads the stored refresh token, exchanges it, and returns the new pair. If nothing is
    /// stored it throws ``NetworkError/sessionExpired``.
    func tokenManagerRefreshHandler() -> TokenManager.RefreshHandler {
        { storage in
            guard let refreshToken = try await storage.refreshToken() else {
                throw NetworkError.sessionExpired
            }
            return TokenPair(oauth: try await self.refresh(refreshToken: refreshToken))
        }
    }
}
