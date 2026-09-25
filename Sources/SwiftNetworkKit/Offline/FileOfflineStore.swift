import Foundation

/// An ``OfflineStore`` backed by a single JSON file. The queue is loaded on first access and
/// rewritten on every mutation, so it survives app launches.
///
/// Persistence problems are reported through `logger` rather than dropped silently: a failed write
/// (the queue then only lives in memory for this launch), a file that cannot be read (left untouched,
/// and not overwritten by later mutations), and a file that is not valid JSON (moved aside to
/// `<file>.corrupt` and replaced with an empty queue).
public actor FileOfflineStore: OfflineStore {

    private let fileURL: URL
    private let logger: any NetworkLogger
    private var loaded: [PersistedRequest]?

    /// - Parameters:
    ///   - fileURL: where to write. Defaults to
    ///     `<Application Support>/SwiftNetworkKit/offline-queue.json`.
    ///   - logger: receives a line whenever the queue file cannot be read, written or parsed.
    public init(fileURL: URL? = nil, logger: any NetworkLogger = ConsoleNetworkLogger()) {
        self.fileURL = fileURL ?? Self.defaultURL()
        self.logger = logger
    }

    public func append(_ request: PersistedRequest) async {
        guard var queue = load() else { return skipped("append") }
        queue.append(request)
        save(queue)
    }

    public func all() async -> [PersistedRequest] {
        load() ?? []
    }

    public func update(_ request: PersistedRequest) async {
        guard var queue = load() else { return skipped("update") }
        guard let index = queue.firstIndex(where: { $0.id == request.id }) else { return }
        queue[index] = request
        save(queue)
    }

    public func remove(_ id: RequestID) async {
        guard var queue = load() else { return skipped("remove") }
        queue.removeAll { $0.id == id }
        save(queue)
    }

    public func removeAll() async {
        save([])
    }

    // MARK: - Internals

    /// The queue, or `nil` when the file exists but cannot be read right now. That state is not cached
    /// so the next call retries, and mutations back off so they cannot overwrite what is on disk.
    private func load() -> [PersistedRequest]? {
        if let loaded { return loaded }
        guard FileManager.default.fileExists(atPath: fileURL.path) else {
            loaded = []
            return []
        }
        let data: Data
        do {
            data = try Data(contentsOf: fileURL)
        } catch {
            logger.log("offline queue file could not be read, leaving it untouched: \(error)", level: .error)
            return nil
        }
        do {
            let queue = try JSONDecoder().decode([PersistedRequest].self, from: data)
            loaded = queue
            return queue
        } catch {
            quarantineCorruptFile(error)
            loaded = []
            return []
        }
    }

    private func save(_ queue: [PersistedRequest]) {
        loaded = queue
        do {
            try FileManager.default.createDirectory(
                at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true
            )
            try JSONEncoder().encode(queue).write(to: fileURL, options: [.atomic, .completeFileProtectionUnlessOpen])
        } catch {
            logger.log(
                "offline queue could not be saved, queued requests will not survive a relaunch: \(error)",
                level: .error
            )
        }
    }

    private func skipped(_ operation: String) {
        logger.log("offline queue \(operation) skipped because the queue file could not be read", level: .error)
    }

    private func quarantineCorruptFile(_ error: any Error) {
        let aside = fileURL.appendingPathExtension("corrupt")
        try? FileManager.default.removeItem(at: aside)
        do {
            try FileManager.default.moveItem(at: fileURL, to: aside)
            logger.log(
                "offline queue file was not valid JSON, moved to \(aside.lastPathComponent): \(error)", level: .error)
        } catch {
            logger.log("offline queue file was not valid JSON and could not be moved aside: \(error)", level: .error)
        }
    }

    private static func defaultURL() -> URL {
        let base =
            FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return
            base
            .appendingPathComponent("SwiftNetworkKit", isDirectory: true)
            .appendingPathComponent("offline-queue.json")
    }
}
