import Foundation

/// An ``OfflineStore`` backed by a single JSON file. The queue is loaded on first access and
/// rewritten on every mutation, so it survives app launches.
public actor FileOfflineStore: OfflineStore {

    private let fileURL: URL
    private var loaded: [PersistedRequest]?

    /// - Parameter fileURL: where to write. Defaults to
    ///   `<Application Support>/SwiftNetworkKit/offline-queue.json`.
    public init(fileURL: URL? = nil) {
        self.fileURL = fileURL ?? Self.defaultURL()
    }

    public func append(_ request: PersistedRequest) async {
        var queue = load()
        queue.append(request)
        save(queue)
    }

    public func all() async -> [PersistedRequest] {
        load()
    }

    public func update(_ request: PersistedRequest) async {
        var queue = load()
        guard let index = queue.firstIndex(where: { $0.id == request.id }) else { return }
        queue[index] = request
        save(queue)
    }

    public func remove(_ id: RequestID) async {
        var queue = load()
        queue.removeAll { $0.id == id }
        save(queue)
    }

    public func removeAll() async {
        save([])
    }

    // MARK: - Internals

    private func load() -> [PersistedRequest] {
        if let loaded { return loaded }
        let queue = (try? Data(contentsOf: fileURL))
            .flatMap { try? JSONDecoder().decode([PersistedRequest].self, from: $0) } ?? []
        loaded = queue
        return queue
    }

    private func save(_ queue: [PersistedRequest]) {
        loaded = queue
        try? FileManager.default.createDirectory(
            at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
        )
        try? JSONEncoder().encode(queue).write(to: fileURL, options: .atomic)
    }

    private static func defaultURL() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base
            .appendingPathComponent("SwiftNetworkKit", isDirectory: true)
            .appendingPathComponent("offline-queue.json")
    }
}
