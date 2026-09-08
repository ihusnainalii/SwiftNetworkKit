import Foundation

/// A successful OAuth 2.0 token response (RFC 6749 §5.1).
public struct OAuthTokenResponse: Sendable, Hashable, Decodable {
    public let accessToken: String
    public let refreshToken: String?
    /// Seconds until the access token expires, if the server said.
    public let expiresIn: TimeInterval?
    public let tokenType: String
    public let scope: String?
    /// When this response was received (defaults to decode time). Not sent by the server.
    public var receivedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case refreshToken = "refresh_token"
        case expiresIn = "expires_in"
        case tokenType = "token_type"
        case scope
        case receivedAt
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.accessToken = try container.decode(String.self, forKey: .accessToken)
        self.refreshToken = try container.decodeIfPresent(String.self, forKey: .refreshToken)
        self.expiresIn = try container.decodeIfPresent(TimeInterval.self, forKey: .expiresIn)
        self.tokenType = try container.decodeIfPresent(String.self, forKey: .tokenType) ?? "Bearer"
        self.scope = try container.decodeIfPresent(String.self, forKey: .scope)
        self.receivedAt = try container.decodeIfPresent(Date.self, forKey: .receivedAt) ?? Date()
    }

    /// Absolute expiry, computed from ``expiresIn`` and ``receivedAt``.
    public var expiryDate: Date? {
        expiresIn.map { receivedAt.addingTimeInterval($0) }
    }
}
