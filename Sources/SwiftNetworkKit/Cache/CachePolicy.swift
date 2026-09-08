import Foundation

/// How a request interacts with the ``ResponseCache``.
public enum CachePolicy: Sendable, Hashable {
    /// Always hit the network; never read or write the cache.
    case ignoreCache
    /// Hit the network; store the response. Never read the cache.
    case networkOnly
    /// Return a fresh cached response if present; otherwise network + store. Falls back to a stale
    /// cached response if the network fails.
    case cacheFirst
    /// Network + store; on network failure fall back to any cached response.
    case networkFirst
    /// Cache only — never touch the network. Missing/expired entry throws ``NetworkError/offline``.
    case cacheOnly
    /// Return the cached response immediately (fresh or stale) and refresh it in the background.
    case staleWhileRevalidate

    var readsCache: Bool {
        switch self {
        case .ignoreCache, .networkOnly: false
        case .cacheFirst, .networkFirst, .cacheOnly, .staleWhileRevalidate: true
        }
    }

    var writesCache: Bool {
        self != .ignoreCache && self != .cacheOnly
    }
}
