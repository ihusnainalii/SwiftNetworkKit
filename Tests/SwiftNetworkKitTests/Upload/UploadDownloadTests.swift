import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

@Suite("Upload & download")
struct UploadDownloadTests {

    private struct Created: Codable, Equatable, Sendable { let id: Int }
    private struct UploadEndpoint: Endpoint {
        typealias Response = Created
        let path = "/upload"
        let method = HTTPMethod.post
    }
    private struct FileEndpoint: Endpoint {
        typealias Response = Data
        let path = "/file"
    }

    private func client(_ transport: MockNetworkTransport, metrics: (any NetworkMetrics)? = nil) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        if let metrics { config.metrics = metrics }
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("upload decodes the response and reports 0 then full progress")
    func uploadProgress() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"id":7}"#.utf8), status: 201))

        let events = Progress()
        var form = MultipartFormData(boundary: "B")
        form.append("hi", name: "note")
        form.append(Data(repeating: 1, count: 1000), name: "blob", fileName: "b.bin")

        let created = try await client(transport).upload(UploadEndpoint(), from: .multipart(form)) { event in
            events.append(event)
        }

        #expect(created == Created(id: 7))
        let seen = events.all
        #expect(seen.first?.completed == 0)
        #expect(seen.last?.fraction == 1)
    }

    @Test("upload surfaces a server error")
    func uploadServerError() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(500))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport).upload(UploadEndpoint(), from: .data(Data("x".utf8)))
        }
        #expect(error?.code == .server)
    }

    @Test("download writes the body to a given destination, creating missing directories")
    func downloadToDestination() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.success(status: 200, headers: [:], body: Data("FILE-CONTENT".utf8)))

        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("nk-dl-\(UUID())/nested", isDirectory: true)
        let destination = dir.appendingPathComponent("out.txt")
        defer { try? FileManager.default.removeItem(at: dir.deletingLastPathComponent()) }

        let url = try await client(transport).download(FileEndpoint(), to: destination)

        #expect(url == destination)
        #expect(try Data(contentsOf: url) == Data("FILE-CONTENT".utf8))
    }

    @Test("download without a destination returns the transport's temp file")
    func downloadTemp() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.success(status: 200, headers: [:], body: Data("bytes".utf8)))
        let url = try await client(transport).download(FileEndpoint())
        defer { try? FileManager.default.removeItem(at: url) }
        #expect(try Data(contentsOf: url) == Data("bytes".utf8))
    }

    @Test("download error cleans up the temp file and throws")
    func downloadError() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(404))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport).download(FileEndpoint())
        }
        #expect(error?.code == .notFound)
    }

    @Test("upload records metrics")
    func uploadMetrics() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"id":1}"#.utf8), status: 201))
        let metrics = InMemoryMetrics()
        _ = try await client(transport, metrics: metrics).upload(UploadEndpoint(), from: .data(Data("x".utf8)))
        let snapshot = await metrics.snapshot()
        #expect(snapshot.requestCount == 1)
        #expect(snapshot.successCount == 1)
        #expect(snapshot.statusCodeHistogram[201] == 1)
    }

    @Test("ProgressEvent.fraction clamps and handles unknown totals")
    func progressFraction() {
        #expect(ProgressEvent(completed: 50, total: 100).fraction == 0.5)
        #expect(ProgressEvent(completed: 200, total: 100).fraction == 1)
        #expect(ProgressEvent(completed: 10, total: -1).fraction == nil)
    }
}

private final class Progress: @unchecked Sendable {
    private let lock = NSLock()
    private var events: [ProgressEvent] = []
    func append(_ event: ProgressEvent) { lock.withLock { events.append(event) } }
    var all: [ProgressEvent] { lock.withLock { events } }
}
