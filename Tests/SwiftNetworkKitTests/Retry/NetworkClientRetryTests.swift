import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

@Suite("NetworkClient retry")
struct NetworkClientRetryTests {

    private struct Thing: Codable, Equatable, Sendable { let ok: Bool }

    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
    }

    private struct PostThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
        let method = HTTPMethod.post
        var retryPolicy: RetryPolicy?
    }

    private let body = Data(#"{"ok":true}"#.utf8)

    private func client(
        _ transport: MockNetworkTransport,
        clock: TestClock,
        policy: RetryPolicy = RetryPolicy(jitter: .none)
    ) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = policy
        config.clock = clock
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("GET 503, 503, 200 succeeds after two backoff waits of 0.5s and 1s")
    func retriesThenSucceeds() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(503), .status(503), .json(body))
        let clock = TestClock()

        let thing = try await client(transport, clock: clock).request(GetThing())

        #expect(thing == Thing(ok: true))
        #expect(transport.requestCount == 3)
        #expect(clock.recordedSleeps == [0.5, 1.0])
    }

    @Test("GET that never recovers throws the last error after maxAttempts")
    func exhaustsAttempts() async {
        let transport = MockNetworkTransport(default: .status(503))
        let clock = TestClock()

        let error = await #expect(throws: NetworkError.self) {
            try await client(transport, clock: clock, policy: RetryPolicy(maxAttempts: 3, jitter: .none))
                .request(GetThing())
        }

        #expect(error?.code == .server)
        #expect(transport.requestCount == 3)
        #expect(clock.recordedSleeps == [0.5, 1.0])
    }

    @Test("POST is not retried by default")
    func postNotRetried() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(503), .json(body))
        let clock = TestClock()

        _ = await #expect(throws: NetworkError.self) {
            try await client(transport, clock: clock).request(PostThing())
        }
        #expect(transport.requestCount == 1)
        #expect(clock.recordedSleeps.isEmpty)
    }

    @Test("per-endpoint retryPolicy opts a POST into retrying")
    func postRetriesWithEndpointOverride() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(503), .json(body))
        let clock = TestClock()
        var endpoint = PostThing()
        endpoint.retryPolicy = RetryPolicy(jitter: .none, retryNonIdempotent: true)

        let thing = try await client(transport, clock: clock).request(endpoint)

        #expect(thing == Thing(ok: true))
        #expect(transport.requestCount == 2)
        #expect(clock.recordedSleeps == [0.5])
    }

    @Test("429 with Retry-After waits exactly that long")
    func honorsRetryAfter() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(429, headers: ["Retry-After": "2"]), .json(body))
        let clock = TestClock()

        _ = try await client(transport, clock: clock).request(GetThing())

        #expect(clock.recordedSleeps == [2.0])
    }

    @Test("cancellation during retry surfaces .cancelled")
    func cancellation() async {
        let transport = MockNetworkTransport(default: .status(503))
        let clock = TestClock()
        let c = client(transport, clock: clock, policy: RetryPolicy(maxAttempts: 5, jitter: .none))

        let task = Task { try await c.request(GetThing()) }
        task.cancel()

        let result = await task.result
        guard case .failure(let error) = result else {
            Issue.record("expected failure")
            return
        }
        #expect(NetworkError.normalize(error).code == .cancelled)
    }
}
