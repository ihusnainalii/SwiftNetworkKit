import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

@Suite("OfflineRequestQueue")
struct OfflineRequestQueueTests {

    private func response(_ status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: URL(string: "https://api.example.com/x")!, statusCode: status,
            httpVersion: "HTTP/1.1", headerFields: nil)!
    }

    private func request(_ path: String) -> URLRequest {
        var r = URLRequest(url: URL(string: "https://api.example.com\(path)")!)
        r.httpMethod = "POST"
        return r
    }

    private func collect(_ stream: AsyncStream<OfflineReplayEvent>, count: Int) async -> [OfflineReplayEvent] {
        var out: [OfflineReplayEvent] = []
        for await event in stream {
            out.append(event)
            if out.count == count { break }
        }
        return out
    }

    @Test("replayNow re-sends queued requests FIFO and emits .replayed")
    func replaysFIFO() async throws {
        let sent = Sent()
        let queue = OfflineRequestQueue(
            store: InMemoryOfflineStore(),
            monitor: MockNetworkMonitor(),
            send: { request in
                await sent.record(request.url!.path)
                return self.response(200)
            }
        )
        _ = try await queue.enqueue(request("/first"), expiresAfter: nil)
        _ = try await queue.enqueue(request("/second"), expiresAfter: nil)

        let events = await queue.events()
        async let collected = collect(events, count: 2)
        await queue.replayNow()

        #expect(await sent.paths == ["/first", "/second"])
        #expect(await queue.pendingCount == 0)
        let kinds = await collected.map(\.kind)
        #expect(kinds == ["replayed", "replayed"])
    }

    @Test("an expired request is dropped and emits .expired")
    func expired() async throws {
        let queue = OfflineRequestQueue(
            store: InMemoryOfflineStore(),
            monitor: MockNetworkMonitor(),
            send: { _ in self.response(200) }
        )
        _ = try await queue.enqueue(request("/stale"), expiresAfter: -1)  // already expired

        let events = await queue.events()
        async let collected = collect(events, count: 1)
        await queue.replayNow()

        #expect(await collected.first?.kind == "expired")
        #expect(await queue.pendingCount == 0)
    }

    @Test("a failed re-send keeps the request queued and emits .failed")
    func failedStaysQueued() async throws {
        let queue = OfflineRequestQueue(
            store: InMemoryOfflineStore(),
            monitor: MockNetworkMonitor(),
            send: { _ in throw NetworkError.noInternet }
        )
        _ = try await queue.enqueue(request("/retry-me"), expiresAfter: nil)

        let events = await queue.events()
        async let collected = collect(events, count: 1)
        await queue.replayNow()

        #expect(await collected.first?.kind == "failed")
        #expect(await queue.pendingCount == 1)
    }

    @Test("connectivity returning triggers an automatic replay")
    func autoReplayOnReconnect() async throws {
        let sent = Sent()
        let monitor = MockNetworkMonitor(initial: .unsatisfied)
        let queue = OfflineRequestQueue(
            store: InMemoryOfflineStore(),
            monitor: monitor,
            send: { request in
                await sent.record(request.url!.path)
                return self.response(201)
            }
        )
        _ = try await queue.enqueue(request("/deferred"), expiresAfter: nil)

        await monitor.send(.satisfied(.wifi))
        for _ in 0..<200 where await queue.pendingCount != 0 { await Task.yield() }
        #expect(await sent.paths == ["/deferred"])
    }
}

private actor Sent {
    private(set) var paths: [String] = []
    func record(_ path: String) { paths.append(path) }
}

extension OfflineReplayEvent {
    fileprivate var kind: String {
        switch self {
        case .replayed: "replayed"
        case .failed: "failed"
        case .expired: "expired"
        }
    }
}
