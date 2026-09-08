import Foundation

/// A request captured while offline, waiting to be replayed. Persisted as JSON.
public struct PersistedRequest: Codable, Sendable, Hashable {
    public let id: RequestID
    /// The `URLRequest` archived with `NSKeyedArchiver` (method, URL, headers and body included).
    public let urlRequestData: Data
    public let createdAt: Date
    public let expiresAt: Date?
    public var attempts: Int

    public init(
        id: RequestID = RequestID(),
        urlRequestData: Data,
        createdAt: Date = Date(),
        expiresAt: Date? = nil,
        attempts: Int = 0
    ) {
        self.id = id
        self.urlRequestData = urlRequestData
        self.createdAt = createdAt
        self.expiresAt = expiresAt
        self.attempts = attempts
    }

    var isExpired: Bool {
        guard let expiresAt else { return false }
        return expiresAt <= Date()
    }
}
