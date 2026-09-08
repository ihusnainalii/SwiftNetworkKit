import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("NetworkClient request management")
struct NetworkClientManagementTests {

    private struct Thing: Codable, Equatable, Sendable { let v: Int }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
        var deduplicate: Bool?
        var priority: RequestPriority = .normal
    }
    private let body = Data(#"{"v":1}"#.utf8)

    private func client(
        _ transport: MockNetworkTransport,
        dedup: Bool = false,
        maxConcurrent: Int = 6
    ) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.enableDeduplication = dedup
        config.maxConcurrentRequests = maxConcurrent
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("cancel(id:) cancels a specific in-flight request")
    func cancelByID() async throws {
        let transport = MockNetworkTransport(latency: .milliseconds(300))
        transport.enqueue(.json(body))
        let c = client(transport)
        let id = RequestID()

        let task = Task { try await c.request(GetThing(), id: id) }
        try await Task.sleep(for: .milliseconds(20))
        await c.cancel(id)

        let result = await task.result
        guard case .failure(let error) = result else { Issue.record("expected cancellation"); return }
        #expect(NetworkError.normalize(error).code == .cancelled)
    }

    @Test("cancelAll() cancels every in-flight request")
    func cancelAll() async throws {
        let transport = MockNetworkTransport(latency: .milliseconds(300))
        let c = client(transport)

        let tasks = (0..<5).map { _ in Task { try await c.request(GetThing()) } }
        try await Task.sleep(for: .milliseconds(20))
        await c.cancelAll()

        var cancelledCount = 0
        for task in tasks {
            if case .failure(let error) = await task.result,
               NetworkError.normalize(error).code == .cancelled {
                cancelledCount += 1
            }
        }
        #expect(cancelledCount == 5)
    }

    @Test("cancelling the caller task propagates")
    func callerCancellation() async throws {
        let transport = MockNetworkTransport(latency: .milliseconds(300))
        transport.enqueue(.json(body))
        let c = client(transport)

        let task = Task { try await c.request(GetThing()) }
        try await Task.sleep(for: .milliseconds(20))
        task.cancel()
        guard case .failure(let error) = await task.result else { Issue.record("expected failure"); return }
        #expect(NetworkError.normalize(error).code == .cancelled)
    }

    @Test("deduplication: concurrent identical GETs hit the transport once")
    func deduplication() async throws {
        let transport = MockNetworkTransport(latency: .milliseconds(30))
        transport.enqueue(.json(body), .json(body), .json(body))
        let c = client(transport, dedup: true)

        let results = try await withThrowingTaskGroup(of: Thing.self) { group in
            for _ in 0..<3 { group.addTask { try await c.request(GetThing()) } }
            return try await group.reduce(into: [Thing]()) { $0.append($1) }
        }
        #expect(results == Array(repeating: Thing(v: 1), count: 3))
        #expect(transport.requestCount == 1)
    }

    @Test("deduplication is skipped for POST")
    func noDedupForPost() async throws {
        struct PostThing: Endpoint {
            typealias Response = Thing
            let path = "/thing"
            let method = HTTPMethod.post
            var deduplicate: Bool? { true }
        }
        let transport = MockNetworkTransport(latency: .milliseconds(20))
        transport.enqueue(.json(body), .json(body))
        let c = client(transport, dedup: true)

        async let a = c.request(PostThing())
        async let b = c.request(PostThing())
        _ = try await (a, b)
        #expect(transport.requestCount == 2)
    }

    @Test("maxConcurrentRequests bounds the whole client")
    func clientConcurrencyLimit() async throws {
        let transport = MockNetworkTransport(default: .json(body), latency: .milliseconds(15))
        let c = client(transport, maxConcurrent: 2)

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<8 { group.addTask { _ = try await c.request(GetThing()) } }
            try await group.waitForAll()
        }
        #expect(transport.recordedRequests.count == 8)
        // hard to assert peak without instrumenting the transport; the concurrency test in
        // RequestQueueTests covers the invariant. Here we just confirm nothing deadlocked.
    }
}
