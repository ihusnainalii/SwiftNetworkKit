import Foundation

/// A key/value store of ``CachedResponse`` values. The client computes the key (method + URL, plus a
/// fingerprint of the `Authorization` value), so a store never has to know the keying rules.
///
/// Built-ins: ``MemoryCacheStore`` (default) and ``DiskCacheStore``.
public protocol ResponseCache: Sendable {
    func value(forKey key: String) async -> CachedResponse?
    func setValue(_ value: CachedResponse, forKey key: String) async
    func remove(forKey key: String) async
    func removeAll() async
}

/// The cache key for a request: `METHOD URL` plus a fingerprint of the `Authorization` value, so
/// responses for different accounts (or an account and an anonymous caller) never collide.
enum CacheKey {
    static func make(method: String, url: URL?, authorization: String?) -> String {
        "\(method) \(url?.absoluteString ?? "?")\(AuthFingerprint.suffix(for: authorization))"
    }
}
