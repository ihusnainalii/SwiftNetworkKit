import Foundation

/// A key/value store of ``CachedResponse`` values. The client computes the key (method + URL, plus
/// whether an `Authorization` header is present), so a store never has to know the keying rules.
///
/// Built-ins: ``MemoryCacheStore`` (default) and ``DiskCacheStore``.
public protocol ResponseCache: Sendable {
    func value(forKey key: String) async -> CachedResponse?
    func setValue(_ value: CachedResponse, forKey key: String) async
    func remove(forKey key: String) async
    func removeAll() async
}

/// The cache key for a request: `METHOD URL` plus an `+auth` marker when an `Authorization` header
/// is set, so an authenticated and an anonymous response for the same URL don't collide.
enum CacheKey {
    static func make(method: String, url: URL?, isAuthenticated: Bool) -> String {
        "\(method) \(url?.absoluteString ?? "?")\(isAuthenticated ? " +auth" : "")"
    }
}
