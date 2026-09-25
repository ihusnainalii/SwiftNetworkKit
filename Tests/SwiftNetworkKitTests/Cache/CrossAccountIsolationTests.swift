import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

/// One client, several accounts: a response fetched with one token must never be served to, or shared
/// with, a request made with another.
@Suite("Cross-account isolation")
struct CrossAccountIsolationTests {

    private struct Thing: Codable, Equatable, Sendable { let v: String }

    private func body(_ v: String) -> Data { Data(#"{"v":"\#(v)"}"#.utf8) }

    /// Authenticated GET whose bearer token is fixed per endpoint value, so two of them can run at
    /// the same time as different accounts.
    private struct GetMeAs: Endpoint {
        typealias Response = Thing
        let user: String
        let path = "/me"
        var authentication: AuthRequirement {
            .custom(
                CustomAuth { [user] request, _ in
                    request.setValue("Bearer \(user)", forHTTPHeaderField: "Authorization")
                })
        }
    }

    private struct GetMe: Endpoint {
        typealias Response = Thing
        let path = "/me"
        var authentication: AuthRequirement = .required
    }

    private struct GetPublic: Endpoint {
        typealias Response = Thing
        let path = "/public"
    }

    @Test("a cached response is not served after the token changes")
    func cacheIsPerToken() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(body("alice"), headers: ["Cache-Control": "max-age=60"]),
            .json(body("bob"), headers: ["Cache-Control": "max-age=60"])
        )
        let storage = InMemoryTokenStorage(seed: TokenPair(accessToken: "alice-token"))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tokenStorage = storage
        config.cache = .memory(policy: .cacheFirst)
        let client = NetworkClient(configuration: config, transport: transport)

        #expect(try await client.request(GetMe()) == Thing(v: "alice"))

        try await storage.store(TokenPair(accessToken: "bob-token"))
        #expect(try await client.request(GetMe()) == Thing(v: "bob"))
        #expect(transport.requestCount == 2)
    }

    @Test("the same token still hits its own cache entry")
    func sameTokenStillCaches() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(body("alice"), headers: ["Cache-Control": "max-age=60"]))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tokenStorage = InMemoryTokenStorage(seed: TokenPair(accessToken: "alice-token"))
        config.cache = .memory(policy: .cacheFirst)
        let client = NetworkClient(configuration: config, transport: transport)

        _ = try await client.request(GetMe())
        _ = try await client.request(GetMe())
        #expect(transport.requestCount == 1)
    }

    @Test("concurrent GETs with different tokens are not deduplicated into one")
    func dedupIsPerToken() async throws {
        let transport = MockNetworkTransport(latency: .milliseconds(40))
        transport.enqueue(.json(body("alice")), .json(body("bob")))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.enableDeduplication = true
        let client = NetworkClient(configuration: config, transport: transport)

        async let alice = client.request(GetMeAs(user: "alice"))
        async let bob = client.request(GetMeAs(user: "bob"))
        let (a, b) = try await (alice, bob)

        #expect(transport.requestCount == 2)
        #expect(Set([a.v, b.v]) == ["alice", "bob"])
    }

    @Test("concurrent GETs with the same token are still deduplicated")
    func dedupSameTokenStillCollapses() async throws {
        let transport = MockNetworkTransport(latency: .milliseconds(40))
        transport.enqueue(.json(body("alice")), .json(body("alice")))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.enableDeduplication = true
        let client = NetworkClient(configuration: config, transport: transport)

        async let first = client.request(GetMeAs(user: "alice"))
        async let second = client.request(GetMeAs(user: "alice"))
        _ = try await (first, second)

        #expect(transport.requestCount == 1)
    }

    @Test("clearCache() empties the response store")
    func clearCacheEmptiesStore() async throws {
        let transport = MockNetworkTransport(default: .json(body("x"), headers: ["Cache-Control": "max-age=60"]))
        let store = MemoryCacheStore()
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.cache = CacheConfiguration(store: store, defaultPolicy: .cacheFirst)
        let client = NetworkClient(configuration: config, transport: transport)

        _ = try await client.request(GetPublic())
        #expect(await store.count == 1)

        await client.clearCache()
        #expect(await store.count == 0)
    }

    @Test("an expired session clears the cache")
    func sessionExpiryClearsCache() async throws {
        struct RefreshDenied: Error {}
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(body("public"), headers: ["Cache-Control": "max-age=60"]),
            .success(status: 401, headers: [:], body: Data(#"{"message":"expired"}"#.utf8))
        )
        let store = MemoryCacheStore()
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tokenStorage = InMemoryTokenStorage(seed: TokenPair(accessToken: "t", refreshToken: "r"))
        config.cache = CacheConfiguration(store: store, defaultPolicy: .cacheFirst)
        let client = NetworkClient(
            configuration: config, transport: transport,
            refresh: { _ in throw RefreshDenied() }
        )

        _ = try await client.request(GetPublic())
        #expect(await store.count == 1)

        _ = try? await client.request(GetMe())
        #expect(await store.count == 0)
    }
}
