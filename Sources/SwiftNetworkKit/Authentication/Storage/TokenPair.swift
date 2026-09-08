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
