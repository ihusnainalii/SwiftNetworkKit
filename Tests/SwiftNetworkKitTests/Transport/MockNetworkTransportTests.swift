import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("MockNetworkTransport rules & scenarios")
struct MockNetworkTransportTests {

    private struct Thing: Codable, Equatable, Sendable { let v: Int }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path: String
    }

    private func client(_ transport: MockNetworkTransport) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("path/method matchers respond regardless of request order")
    func matchers() async throws {
        let transport = MockNetworkTransport(default: .status(404))
        transport
            .stub(pathContains: "/users", with: .json(Data(#"{"v":1}"#.utf8)))
            .stub(method: .post, pathContains: "/orders", with: .json(Data(#"{"v":2}"#.utf8), status: 201))

        let c = client(transport)
        #expect(try await c.request(GetThing(path: "/users")) == Thing(v: 1))
        #expect(try await c.request(GetThing(path: "/users")) == Thing(v: 1))  // reusable

        struct PostOrder: Endpoint {
            typealias Response = Thing
            let path = "/orders"
            let method = HTTPMethod.post
        }
        #expect(try await c.request(PostOrder()) == Thing(v: 2))

        // unmatched -> default 404
        _ = await #expect(throws: NetworkError.self) { try await c.request(GetThing(path: "/widgets")) }
    }

    @Test("a rule can hold a scripted sequence")
    func scriptedRule() async throws {
        let transport = MockNetworkTransport()
        transport.stub(pathContains: "/flaky", with: .status(503), .status(503), .json(Data(#"{"v":9}"#.utf8)))

        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = RetryPolicy(maxAttempts: 3, jitter: .none)
        config.clock = TestClock()
        let thing = try await NetworkClient(configuration: config, transport: transport)
            .request(GetThing(path: "/flaky"))
        #expect(thing == Thing(v: 9))
        #expect(transport.requestCount == 3)
    }

    @Test("MockScenario.tokenExpired 401s once then succeeds")
    func scenario() async throws {
        let transport = MockScenario.tokenExpired(body: Data(#"{"v":7}"#.utf8)).transport()
        let refreshed = Counter()
        let client = NetworkClient(
            configuration: NetworkConfiguration(
                baseURL: "https://api.example.com",
                tokenStorage: InMemoryTokenStorage(seed: TokenPair(accessToken: "old"))),
            transport: transport,
            refresh: { _ in
                await refreshed.increment()
                return TokenPair(accessToken: "new")
            }
        )
        struct Secured: Endpoint {
            typealias Response = Thing
            let path = "/me"
            var authentication: AuthRequirement { .required }
        }
        #expect(try await client.request(Secured()) == Thing(v: 7))
        #expect(await refreshed.value == 1)
    }
}
