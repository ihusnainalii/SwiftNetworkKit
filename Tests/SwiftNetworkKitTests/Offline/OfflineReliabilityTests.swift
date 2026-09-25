import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

/// A queued request is a user's unsent work. Losing one has to be visible, never silent.
@Suite("Offline reliability")
struct OfflineReliabilityTests {

    private func response(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.example.com/x")!, statusCode: status,
            httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    private func post(_ path: String) -> URLRequest {
        var request = URLRequest(url: URL(string: "https://api.example.com\(path)")!)
        request.httpMethod = "POST"
        return request
    }

    private func scratchDirectory() throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("nk-offline-\(UUID())")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: Replay

    @Test("a queued request that cannot be rebuilt is dropped with a .failed event")
    func unarchivableEmitsFailed() async {
        let store = InMemoryOfflineStore()
        await store.append(PersistedRequest(urlRequestData: Data("garbage".utf8)))
        let queue = OfflineRequestQueue(
            store: store, monitor: MockNetworkMonitor(), send: { _ in self.response(200) })

        let events = await queue.events()
        async let first: OfflineReplayEvent? = {
            for await event in events { return event }
            return nil
        }()
        await queue.replayNow()

        guard case .failed(_, let error)? = await first else {
            Issue.record("expected a .failed event")
            return
        }
        #expect(error.code == .encoding)
        #expect(await queue.pendingCount == 0)
    }

    @Test("a request that keeps failing is dropped once it reaches the attempt limit")
    func attemptLimit() async throws {
        let queue = OfflineRequestQueue(
            store: InMemoryOfflineStore(), monitor: MockNetworkMonitor(),
            send: { _ in throw NetworkError.noInternet })
        _ = try await queue.enqueue(post("/never"), expiresAfter: nil)

        for _ in 1..<OfflineRequestQueue.maxReplayAttempts { await queue.replayNow() }
        #expect(await queue.pendingCount == 1)

        await queue.replayNow()
        #expect(await queue.pendingCount == 0)
    }

    // MARK: FileOfflineStore

    @Test("a corrupt queue file is moved aside and reported")
    func corruptFileIsQuarantined() async throws {
        let dir = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let file = dir.appendingPathComponent("queue.json")
        try Data("not json".utf8).write(to: file)
        let logger = CapturingLogger()

        let store = FileOfflineStore(fileURL: file, logger: logger)

        #expect(await store.all().isEmpty)
        #expect(FileManager.default.fileExists(atPath: file.appendingPathExtension("corrupt").path))
        #expect(logger.entries.contains { $0.level == .error && $0.line.contains("not valid JSON") })
    }

    @Test("a failed write is reported and the in-memory queue keeps working")
    func saveFailureIsReported() async throws {
        let dir = try scratchDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        // The would-be parent directory is a regular file, so the write cannot succeed.
        let blocker = dir.appendingPathComponent("blocker")
        try Data("x".utf8).write(to: blocker)
        let logger = CapturingLogger()
        let store = FileOfflineStore(fileURL: blocker.appendingPathComponent("queue.json"), logger: logger)

        let request = PersistedRequest(urlRequestData: Data("x".utf8))
        await store.append(request)

        #expect(await store.all().map(\.id) == [request.id])
        #expect(logger.entries.contains { $0.level == .error && $0.line.contains("could not be saved") })
    }

    @Test(
        "an unreadable queue file is left untouched by later mutations",
        .enabled(if: geteuid() != 0, "permission bits do not apply to root"))
    func unreadableFileIsNotOverwritten() async throws {
        let dir = try scratchDirectory()
        let file = dir.appendingPathComponent("queue.json")
        defer {
            try? FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)
            try? FileManager.default.removeItem(at: dir)
        }
        let original = PersistedRequest(urlRequestData: Data("one".utf8))
        await FileOfflineStore(fileURL: file).append(original)

        try FileManager.default.setAttributes([.posixPermissions: 0o000], ofItemAtPath: file.path)
        let logger = CapturingLogger()
        let locked = FileOfflineStore(fileURL: file, logger: logger)
        await locked.append(PersistedRequest(urlRequestData: Data("two".utf8)))
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)

        #expect(logger.entries.contains { $0.line.contains("could not be read") })
        #expect(await FileOfflineStore(fileURL: file).all().map(\.id) == [original.id])
    }
}
