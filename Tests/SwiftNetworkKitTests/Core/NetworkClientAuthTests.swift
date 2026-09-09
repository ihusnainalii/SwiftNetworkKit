import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

@Suite("NetworkClient authentication")
struct NetworkClientAuthTests {

    private struct Profile: Codable, Equatable, Sendable { let id: Int }

    private struct SecureEndpoint: Endpoint {
        typealias Response = Profile
        let path = "/me"
        var authentication: AuthRequirement = .required
    }

    private func unauthorized() -> MockNetworkTransport.Outcome {
        .success(status: 401, headers: [:], body: Data(#"{"message":"expired"}"#.utf8))
    }

    private func profileBody() -> Data { Data(#"{"id":1}"#.utf8) }

    @Test("401 then 200: refreshes once, retries, succeeds")
    func refreshAndRetry() async throws {
        let refreshCount = Counter()
        let transport = MockNetworkTransport()
        transport.enqueue(unauthorized(), .json(profileBody()))

        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"),
            transport: transport,
            refresh: { _ in
                await refreshCount.increment()
                return TokenPair(accessToken: "fresh")
            }
        )

        let profile = try await client.request(SecureEndpoint())
        #expect(profile == Profile(id: 1))
        #expect(await refreshCount.value == 1)
        #expect(transport.requestCount == 2)

        // The retried request carried the refreshed bearer token.
        #expect(transport.recordedRequests.last?.value(forHTTPHeaderField: "Authorization") == "Bearer fresh")
    }

    @Test("401 twice: surfaces .sessionExpired and calls the logout hook")
    func doubleUnauthorized() async throws {
        let loggedOut = Counter()
        let transport = MockNetworkTransport()
        transport.enqueue(unauthorized(), unauthorized(), unauthorized())

        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"),
            transport: transport,
            refresh: { _ in TokenPair(accessToken: "fresh") },
            onSessionExpired: { await loggedOut.increment() }
        )

        let error = await #expect(throws: NetworkError.self) {
            try await client.request(SecureEndpoint())
        }
        #expect(error?.code == .sessionExpired)
        #expect(await loggedOut.value == 1)
    }

    @Test("concurrent requests hitting 401 share a single refresh")
    func concurrentRefresh() async throws {
        let refreshCount = Counter()
        let transport = MockNetworkTransport()
        // 3 requests: each gets a 401, then a 200 after refresh.
        transport.enqueue(
            unauthorized(), unauthorized(), unauthorized(),
            .json(profileBody()), .json(profileBody()), .json(profileBody())
        )

        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"),
            transport: transport,
            refresh: { _ in
                await refreshCount.increment()
                try await Task.sleep(for: .milliseconds(20))
                return TokenPair(accessToken: "fresh")
            }
        )

        try await withThrowingTaskGroup(of: Profile.self) { group in
            for _ in 0..<3 { group.addTask { try await client.request(SecureEndpoint()) } }
            for try await profile in group { #expect(profile == Profile(id: 1)) }
        }
        #expect(await refreshCount.value == 1)
    }

    @Test("no refresh handler: a 401 propagates as .unauthorized")
    func noRefreshHandler() async {
        let transport = MockNetworkTransport()
        transport.enqueue(unauthorized())
        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"),
            transport: transport
        )
        let error = await #expect(throws: NetworkError.self) {
            try await client.request(SecureEndpoint())
        }
        #expect(error?.code == .unauthorized)
    }

    @Test("stored token is attached to the first request")
    func attachesStoredToken() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(profileBody()))
        let storage = InMemoryTokenStorage(seed: TokenPair(accessToken: "stored"))
        let client = NetworkClient(
            configuration: NetworkConfiguration(
                environment: .production(baseURL: URL(string: "https://api.example.com")!),
                tokenStorage: storage
            ),
            transport: transport,
            refresh: { _ in TokenPair(accessToken: "x") }
        )

        _ = try await client.request(SecureEndpoint())
        #expect(transport.recordedRequests.first?.value(forHTTPHeaderField: "Authorization") == "Bearer stored")
    }

    @Test("unauthenticated endpoints are never given a token or refreshed")
    func publicEndpoint() async throws {
        struct PublicEndpoint: Endpoint {
            typealias Response = Profile
            let path = "/public"
        }
        let refreshCount = Counter()
        let transport = MockNetworkTransport()
        transport.enqueue(unauthorized())

        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"),
            transport: transport,
            refresh: { _ in
                await refreshCount.increment()
                return TokenPair(accessToken: "x")
            }
        )

        let error = await #expect(throws: NetworkError.self) {
            try await client.request(PublicEndpoint())
        }
        #expect(error?.code == .unauthorized)
        #expect(await refreshCount.value == 0)
        #expect(transport.recordedRequests.first?.value(forHTTPHeaderField: "Authorization") == nil)
    }
}
