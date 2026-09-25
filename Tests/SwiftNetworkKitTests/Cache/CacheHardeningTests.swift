import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

@Suite("Cache hardening")
struct CacheHardeningTests {

    private struct Thing: Codable, Equatable, Sendable { let v: String }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
    }

    private func entry(_ body: String) -> CachedResponse {
        CachedResponse(data: Data(body.utf8), headers: ["Content-Type": "application/json"], statusCode: 200)
    }

    private func temporaryDirectory() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("nk-cache-\(UUID())")
    }

    @Test("disk cache file names are the SHA-256 of the key")
    func fileNameIsSHA256() {
        // NIST test vector: SHA-256("abc")
        #expect(
            DiskCacheStore.fileName(for: "abc")
                == "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad.json")
        #expect(DiskCacheStore.fileName(for: "GET https://x/a") != DiskCacheStore.fileName(for: "GET https://x/b"))
    }

    @Test("an unreadable disk entry is dropped instead of missing forever")
    func corruptEntryIsRemoved() async throws {
        let dir = temporaryDirectory()
        defer { try? FileManager.default.removeItem(at: dir) }
        let store = DiskCacheStore(directory: dir)
        await store.setValue(entry("ok"), forKey: "k")

        let file = dir.appendingPathComponent(DiskCacheStore.fileName(for: "k"))
        try Data("not json".utf8).write(to: file)

        #expect(await store.value(forKey: "k") == nil)
        #expect(!FileManager.default.fileExists(atPath: file.path))
    }

    @Test("Set-Cookie and other credential headers are not written to the cache")
    func credentialHeadersNotCached() async throws {
        let transport = MockNetworkTransport(
            default: .json(
                Data(#"{"v":"x"}"#.utf8),
                headers: ["Cache-Control": "max-age=60", "Set-Cookie": "session=abc", "X-Trace": "t1"]))
        let store = MemoryCacheStore()
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.cache = CacheConfiguration(store: store, defaultPolicy: .cacheFirst)
        let client = NetworkClient(configuration: config, transport: transport)

        _ = try await client.request(GetThing())

        let key = CacheKey.make(
            method: "GET", url: URL(string: "https://api.example.com/thing"), authorization: nil)
        let cached = try #require(await store.value(forKey: key))
        #expect(cached.headers["Set-Cookie"] == nil)
        #expect(cached.headers["X-Trace"] == "t1")
    }

    @Test("a failing stale-while-revalidate refresh is logged, not discarded")
    func revalidationFailureIsLogged() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"{"v":"stale"}"#.utf8), headers: ["Cache-Control": "max-age=0"]),
            .failure(.noInternet)
        )
        let logger = CapturingLogger()
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.logger = logger
        config.cache = CacheConfiguration(store: MemoryCacheStore(), defaultPolicy: .staleWhileRevalidate)
        let client = NetworkClient(configuration: config, transport: transport)

        _ = try await client.request(GetThing())  // populates the cache
        #expect(try await client.request(GetThing()) == Thing(v: "stale"))  // served stale, refresh fails

        for _ in 0..<500 where !logger.lines.contains(where: { $0.contains("background revalidation failed") }) {
            try await Task.sleep(for: .milliseconds(2))
        }
        #expect(logger.lines.contains { $0.contains("background revalidation failed") })
    }

    @Test("removingCredentials also honors extra names, case-insensitively")
    func extraNames() {
        let headers: HTTPHeaders = ["X-Session": "s", "Content-Type": "application/json"]
        let stripped = headers.removingCredentials(also: ["x-session"])
        #expect(stripped["X-Session"] == nil)
        #expect(stripped["Content-Type"] == "application/json")
    }
}
