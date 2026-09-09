import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("InMemoryMetrics")
struct InMemoryMetricsTests {

    private struct Thing: Codable, Sendable { let ok: Bool }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
    }
    private let ok = Data(#"{"ok":true}"#.utf8)

    @Test("aggregates counts, histogram and percentiles from raw events")
    func aggregation() async {
        let metrics = InMemoryMetrics()
        for _ in 0..<7 { await metrics.record(.requestStarted(RequestID())) }
        for ms in [10, 20, 30, 40, 100] {
            await metrics.record(.success(RequestID(), duration: .milliseconds(ms), status: 200))
        }
        await metrics.record(.failure(RequestID(), .server(dummyContext(500)), status: 500))
        await metrics.record(.failure(RequestID(), .timeout, status: nil))
        await metrics.record(.timeout(RequestID()))
        await metrics.record(.retry(RequestID(), attempt: 2))
        await metrics.record(.tokenRefresh(success: true))
        await metrics.record(.tokenRefresh(success: false))

        let snap = await metrics.snapshot()
        #expect(snap.requestCount == 7)
        #expect(snap.successCount == 5)
        #expect(snap.failureCount == 2)
        #expect(snap.retryCount == 1)
        #expect(snap.timeoutCount == 1)
        #expect(snap.tokenRefreshCount == 2)
        #expect(snap.tokenRefreshSuccessCount == 1)
        #expect(snap.statusCodeHistogram == [200: 5, 500: 1])
        #expect(snap.averageDuration == .milliseconds(40))
        #expect(snap.p95Duration == .milliseconds(100))
    }

    @Test("end-to-end: 10 mixed requests through the client add up")
    func endToEnd() async throws {
        let metrics = InMemoryMetrics()
        let transport = MockNetworkTransport(default: .json(Data(#"{"ok":true}"#.utf8)))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.metrics = metrics
        let client = NetworkClient(configuration: config, transport: transport)

        for i in 0..<10 {
            transport.enqueue(i.isMultiple(of: 3) ? .status(500) : .json(ok))
            _ = try? await client.request(GetThing())
        }

        let snap = await metrics.snapshot()
        #expect(snap.requestCount == 10)
        #expect(snap.successCount + snap.failureCount == 10)
        #expect(snap.failureCount == 4)  // i = 0, 3, 6, 9
        #expect(snap.statusCodeHistogram[200] == 6)
        #expect(snap.statusCodeHistogram[500] == 4)
    }

    @Test("reset() zeroes every counter and the histogram")
    func reset() async {
        let metrics = InMemoryMetrics()
        await metrics.record(.success(RequestID(), duration: .milliseconds(5), status: 200))
        await metrics.record(.failure(RequestID(), .timeout, status: nil))
        await metrics.record(.retry(RequestID(), attempt: 1))
        await metrics.reset()

        let snap = await metrics.snapshot()
        #expect(snap.requestCount == 0)
        #expect(snap.successCount == 0)
        #expect(snap.failureCount == 0)
        #expect(snap.retryCount == 0)
        #expect(snap.statusCodeHistogram.isEmpty)
    }

    private func dummyContext(_ status: Int) -> ResponseContext {
        ResponseContext(
            statusCode: status, headers: [:], data: nil,
            request: URLRequest(url: URL(string: "https://api.example.com")!)
        )
    }
}
