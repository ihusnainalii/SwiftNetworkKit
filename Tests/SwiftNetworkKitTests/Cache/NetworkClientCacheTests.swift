import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("NetworkClient caching")
struct NetworkClientCacheTests {

    private struct Thing: Codable, Equatable, Sendable { let v: String }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
        var cachePolicy: CachePolicy?
    }
    private struct PostThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
        let method = HTTPMethod.post
        var cachePolicy: CachePolicy? = .cacheFirst
    }

    private func body(_ v: String) -> Data { Data(#"{"v":"\#(v)"}"#.utf8) }

    private func client(
        _ transport: MockNetworkTransport,
        _ store: MemoryCacheStore,
        policy: CachePolicy = .networkFirst,
        ttl: TimeInterval = 300
    ) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.cache = CacheConfiguration(store: store, defaultPolicy: policy, defaultTTL: ttl)
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("cacheFirst serves the second call from the cache without hitting the transport")
    func cacheFirst() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(body("one"), headers: ["Cache-Control": "max-age=60"]))
        let store = MemoryCacheStore()
        let c = client(transport, store, policy: .cacheFirst)

        #expect(try await c.request(GetThing()) == Thing(v: "one"))
        #expect(try await c.request(GetThing()) == Thing(v: "one"))
        #expect(transport.requestCount == 1)
    }

    @Test("a 304 revalidation returns the cached body and refreshes it")
    func notModified() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(body("cached"), headers: ["ETag": "\"abc\"", "Cache-Control": "max-age=0"]),
            .status(304, headers: ["ETag": "\"abc\""])
        )
        let store = MemoryCacheStore()
        let c = client(transport, store, policy: .cacheFirst)

        #expect(try await c.request(GetThing()) == Thing(v: "cached"))
        #expect(try await c.request(GetThing()) == Thing(v: "cached"))  // 304 -> served from cache
        #expect(transport.requestCount == 2)
        #expect(transport.recordedRequests.last?.value(forHTTPHeaderField: "If-None-Match") == "\"abc\"")
    }

    @Test("no-store responses are never persisted")
    func noStore() async throws {
        let transport = MockNetworkTransport(default: .json(body("x"), headers: ["Cache-Control": "no-store"]))
        let store = MemoryCacheStore()
        _ = try await client(transport, store, policy: .cacheFirst).request(GetThing())
        #expect(await store.count == 0)
    }

    @Test("networkFirst falls back to a cached response when the network fails")
    func networkFirstFallback() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(body("saved")))  // first call populates the cache
        let store = MemoryCacheStore()
        let c = client(transport, store, policy: .networkFirst)
        _ = try await c.request(GetThing())

        transport.enqueue(.failure(.noInternet))  // second call: offline
        #expect(try await c.request(GetThing()) == Thing(v: "saved"))
    }

    @Test("cacheOnly with an empty cache throws .offline")
    func cacheOnlyMiss() async {
        let transport = MockNetworkTransport()
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport, MemoryCacheStore(), policy: .cacheOnly).request(GetThing())
        }
        #expect(error?.code == .offline)
        #expect(transport.requestCount == 0)
    }

    @Test("staleWhileRevalidate returns the stale value immediately and refreshes in the background")
    func staleWhileRevalidate() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(body("stale"), headers: ["Cache-Control": "max-age=0"]),
            .json(body("fresh"), headers: ["Cache-Control": "max-age=60"])
        )
        let store = MemoryCacheStore()
        let c = client(transport, store, policy: .staleWhileRevalidate)

        #expect(try await c.request(GetThing()) == Thing(v: "stale"))  // populate
        #expect(try await c.request(GetThing()) == Thing(v: "stale"))  // served stale, refresh kicked off

        // wait for the detached refresh to land the fresh value
        for _ in 0..<200 where (await store.value(forKey: cacheKey))?.data != body("fresh") {
            await Task.yield()
        }
        #expect((await store.value(forKey: cacheKey))?.data == body("fresh"))
    }

    @Test("POST responses are not cached even with a cache policy")
    func postNotCached() async throws {
        let transport = MockNetworkTransport(default: .json(body("p")))
        let store = MemoryCacheStore()
        let c = client(transport, store, policy: .cacheFirst)
        _ = try await c.request(PostThing())
        _ = try await c.request(PostThing())
        #expect(transport.requestCount == 2)
        #expect(await store.count == 0)
    }

    private let cacheKey = CacheKey.make(
        method: "GET", url: URL(string: "https://api.example.com/thing"), isAuthenticated: false
    )
}
