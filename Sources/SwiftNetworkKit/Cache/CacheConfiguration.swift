import Foundation

/// Response-caching settings on ``NetworkConfiguration``. Caching is **off** until a ``store`` is set.
public struct CacheConfiguration: Sendable {

    /// Where responses are cached. `nil` disables caching entirely, regardless of policy.
    public var store: (any ResponseCache)?

    /// The policy for requests whose ``Endpoint/cachePolicy`` is `nil`.
    public var defaultPolicy: CachePolicy

    /// Freshness window for a cached entry that carried no `max-age`.
    public var defaultTTL: TimeInterval

    public init(
        store: (any ResponseCache)? = nil,
        defaultPolicy: CachePolicy = .networkFirst,
        defaultTTL: TimeInterval = 300
    ) {
        self.store = store
        self.defaultPolicy = defaultPolicy
        self.defaultTTL = defaultTTL
    }

    /// Caching disabled.
    public static let disabled = CacheConfiguration()

    /// An in-memory cache with the given policy.
    public static func memory(
        policy: CachePolicy = .networkFirst,
        limitBytes: Int = 20 * 1024 * 1024,
        defaultTTL: TimeInterval = 300
    ) -> CacheConfiguration {
        CacheConfiguration(store: MemoryCacheStore(limitBytes: limitBytes), defaultPolicy: policy, defaultTTL: defaultTTL)
    }
}
