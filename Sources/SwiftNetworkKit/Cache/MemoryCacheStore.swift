import Foundation

/// An in-memory ``ResponseCache`` with LRU eviction once the total stored size passes `limitBytes`.
public actor MemoryCacheStore: ResponseCache {

    private var entries: [String: CachedResponse] = [:]
    private var order: [String] = []  // least-recently-used first
    private var totalBytes = 0
    private let limitBytes: Int

    public init(limitBytes: Int = 20 * 1024 * 1024) {
        self.limitBytes = limitBytes
    }

    public func value(forKey key: String) -> CachedResponse? {
        guard let entry = entries[key] else { return nil }
        touch(key)
        return entry
    }

    public func setValue(_ value: CachedResponse, forKey key: String) {
        if let existing = entries[key] { totalBytes -= existing.byteSize }
        entries[key] = value
        totalBytes += value.byteSize
        touch(key)
        evictIfNeeded()
    }

    public func remove(forKey key: String) {
        guard let entry = entries.removeValue(forKey: key) else { return }
        totalBytes -= entry.byteSize
        order.removeAll { $0 == key }
    }

    public func removeAll() {
        entries.removeAll()
        order.removeAll()
        totalBytes = 0
    }

    /// Current number of stored entries (test/inspection).
    public var count: Int { entries.count }

    private func touch(_ key: String) {
        order.removeAll { $0 == key }
        order.append(key)
    }

    private func evictIfNeeded() {
        while totalBytes > limitBytes, let oldest = order.first {
            remove(forKey: oldest)
        }
    }
}
