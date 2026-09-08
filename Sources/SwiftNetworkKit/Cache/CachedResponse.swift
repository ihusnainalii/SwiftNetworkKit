import Foundation

/// A stored HTTP response.
public struct CachedResponse: Sendable, Codable, Hashable {
    public var data: Data
    public var headers: HTTPHeaders
    public var statusCode: Int
    public var storedAt: Date
    public var etag: String?
    /// Server `max-age` in seconds. `0` means "must revalidate every time"; `nil` means the store's
    /// default TTL applies.
    public var maxAge: TimeInterval?

    public init(
        data: Data,
        headers: HTTPHeaders,
        statusCode: Int,
        storedAt: Date = Date(),
        etag: String? = nil,
        maxAge: TimeInterval? = nil
    ) {
        self.data = data
        self.headers = headers
        self.statusCode = statusCode
        self.storedAt = storedAt
        self.etag = etag
        self.maxAge = maxAge
    }

    /// Whether the entry may be served without revalidation, given a fallback `ttl` for entries with
    /// no explicit `max-age`.
    public func isFresh(ttl: TimeInterval, now: Date = Date()) -> Bool {
        let lifetime = maxAge ?? ttl
        guard lifetime > 0 else { return false }
        return now.timeIntervalSince(storedAt) < lifetime
    }

    /// Approximate stored size in bytes (body + headers), for LRU accounting.
    var byteSize: Int {
        data.count + headers.dictionary.reduce(0) { $0 + $1.key.utf8.count + $1.value.utf8.count }
    }
}
