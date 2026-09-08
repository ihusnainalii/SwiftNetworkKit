import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("Cache stores")
struct CacheStoreTests {

    private func entry(_ body: String, maxAge: TimeInterval? = nil, storedAt: Date = Date()) -> CachedResponse {
        CachedResponse(
            data: Data(body.utf8), headers: ["Content-Type": "application/json"],
            statusCode: 200, storedAt: storedAt, etag: "\"\(body)\"", maxAge: maxAge
        )
    }

    @Test("MemoryCacheStore round-trips and honors removeAll")
    func memoryRoundTrip() async {
        let store = MemoryCacheStore()
        await store.setValue(entry("a"), forKey: "k1")
        #expect(await store.value(forKey: "k1")?.data == Data("a".utf8))
        #expect(await store.value(forKey: "missing") == nil)
        await store.removeAll()
        #expect(await store.value(forKey: "k1") == nil)
    }

    @Test("MemoryCacheStore evicts least-recently-used past the byte limit")
    func memoryLRU() async {
        let store = MemoryCacheStore(limitBytes: 300)
        await store.setValue(entry(String(repeating: "x", count: 120)), forKey: "a")
        await store.setValue(entry(String(repeating: "y", count: 120)), forKey: "b")
        _ = await store.value(forKey: "a")                       // 'a' now most-recently-used
        await store.setValue(entry(String(repeating: "z", count: 120)), forKey: "c") // pushes over -> evict 'b'
        #expect(await store.value(forKey: "b") == nil)
        #expect(await store.value(forKey: "a") != nil)
        #expect(await store.value(forKey: "c") != nil)
    }

    @Test("DiskCacheStore persists across instances")
    func diskPersists() async {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("nk-cache-\(UUID())")
        defer { try? FileManager.default.removeItem(at: dir) }

        let a = DiskCacheStore(directory: dir)
        await a.setValue(entry("persisted"), forKey: "GET https://x/y")

        let b = DiskCacheStore(directory: dir)
        #expect(await b.value(forKey: "GET https://x/y")?.data == Data("persisted".utf8))
        await b.remove(forKey: "GET https://x/y")
        #expect(await b.value(forKey: "GET https://x/y") == nil)
    }

    @Test("CachedResponse.isFresh respects max-age and the fallback TTL")
    func freshness() {
        let old = Date().addingTimeInterval(-120)
        #expect(entry("x", maxAge: 60, storedAt: old).isFresh(ttl: 300) == false)
        #expect(entry("x", maxAge: 600, storedAt: old).isFresh(ttl: 10) == true)
        #expect(entry("x", maxAge: nil, storedAt: old).isFresh(ttl: 300) == true)   // uses TTL 300
        #expect(entry("x", maxAge: nil, storedAt: old).isFresh(ttl: 60) == false)
        #expect(entry("x", maxAge: 0, storedAt: Date()).isFresh(ttl: 300) == false) // must-revalidate
    }

    @Test("CachedResponse survives a JSON round-trip")
    func codable() throws {
        let original = entry("body", maxAge: 42)
        let data = try JSONEncoder().encode(original)
        #expect(try JSONDecoder().decode(CachedResponse.self, from: data) == original)
    }

    @Test("CacheControl parses the directives caching needs")
    func cacheControl() {
        #expect(CacheControl(headers: ["Cache-Control": "no-store"]).noStore)
        let maxAge = CacheControl(headers: ["Cache-Control": "public, max-age=120"])
        #expect(maxAge.maxAge == 120)
        #expect(maxAge.mustRevalidate == false)
        #expect(CacheControl(headers: ["Cache-Control": "no-cache"]).mustRevalidate)
        #expect(CacheControl(headers: ["Cache-Control": "max-age=0"]).mustRevalidate)
        #expect(CacheControl(headers: [:]).maxAge == nil)
    }
}
