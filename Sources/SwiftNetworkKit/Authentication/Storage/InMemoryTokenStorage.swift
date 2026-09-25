import Foundation

/// Non-persistent storage. Good for tests and for apps that intentionally keep tokens in memory only.
public actor InMemoryTokenStorage: TokenStorage {
    private var storage: [String: Data]

    public init() {
        storage = [:]
    }

    /// Seeds the storage with an initial token pair.
    public init(seed pair: TokenPair) {
        storage = [:]
        do {
            storage[InMemoryTokenStorage.tokenPairKey] = try JSONEncoder().encode(pair)
        } catch {
            // A `TokenPair` is plain strings and dates, so this cannot happen; do not hide it if it does.
            assertionFailure("InMemoryTokenStorage could not encode its seed TokenPair: \(error)")
        }
    }

    public func data(forKey key: String) -> Data? {
        storage[key]
    }

    public func setData(_ data: Data?, forKey key: String) {
        storage[key] = data
    }

    public func removeAll() {
        storage.removeAll()
    }
}
