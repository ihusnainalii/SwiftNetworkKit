import Foundation

/// A ``ResponseCache`` that persists entries as JSON files in a directory, with LRU eviction by
/// total size. Survives app launches.
public actor DiskCacheStore: ResponseCache {

    private let directory: URL
    private let limitBytes: Int
    private let fileManager = FileManager.default

    /// - Parameters:
    ///   - directory: where to write files. Defaults to `<Caches>/SwiftNetworkKit`.
    ///   - limitBytes: evict least-recently-used files once the total exceeds this.
    public init(directory: URL? = nil, limitBytes: Int = 100 * 1024 * 1024) {
        self.directory = directory ?? Self.defaultDirectory()
        self.limitBytes = limitBytes
        try? fileManager.createDirectory(at: self.directory, withIntermediateDirectories: true)
    }

    public func value(forKey key: String) -> CachedResponse? {
        let url = fileURL(for: key)
        guard let data = try? Data(contentsOf: url),
              let entry = try? JSONDecoder().decode(CachedResponse.self, from: data) else { return nil }
        try? fileManager.setAttributes([.modificationDate: Date()], ofItemAtPath: url.path) // LRU touch
        return entry
    }

    public func setValue(_ value: CachedResponse, forKey key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        try? data.write(to: fileURL(for: key), options: .atomic)
        evictIfNeeded()
    }

    public func remove(forKey key: String) {
        try? fileManager.removeItem(at: fileURL(for: key))
    }

    public func removeAll() {
        let contents = (try? fileManager.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        for url in contents { try? fileManager.removeItem(at: url) }
    }

    // MARK: - Internals

    private func fileURL(for key: String) -> URL {
        directory.appendingPathComponent(Self.fileName(for: key))
    }

    /// A filesystem-safe, collision-resistant name from the key.
    static func fileName(for key: String) -> String {
        var hash: UInt64 = 5381
        for byte in key.utf8 { hash = (hash &* 33) ^ UInt64(byte) }
        return String(hash, radix: 36) + "-" + String(key.utf8.count) + ".json"
    }

    private static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("SwiftNetworkKit", isDirectory: true)
    }

    private func evictIfNeeded() {
        let keys: [URLResourceKey] = [.fileSizeKey, .contentModificationDateKey]
        var files = ((try? fileManager.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: keys
        )) ?? []).compactMap { url -> (url: URL, size: Int, date: Date)? in
            let values = try? url.resourceValues(forKeys: Set(keys))
            return (url, values?.fileSize ?? 0, values?.contentModificationDate ?? .distantPast)
        }
        var total = files.reduce(0) { $0 + $1.size }
        guard total > limitBytes else { return }
        files.sort { $0.date < $1.date } // oldest first
        for file in files where total > limitBytes {
            try? fileManager.removeItem(at: file.url)
            total -= file.size
        }
    }
}
