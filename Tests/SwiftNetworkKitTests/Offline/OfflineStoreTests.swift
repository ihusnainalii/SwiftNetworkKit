import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("Offline store & archiving")
struct OfflineStoreTests {

    private func request(_ path: String) -> PersistedRequest {
        var urlRequest = URLRequest(url: URL(string: "https://api.example.com\(path)")!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.httpBody = Data(#"{"x":1}"#.utf8)
        return PersistedRequest(urlRequestData: URLRequestArchive.archive(urlRequest)!)
    }

    @Test("URLRequest archiving round-trips method, URL, headers and body")
    func archiveRoundTrip() throws {
        var original = URLRequest(url: URL(string: "https://api.example.com/things?q=1")!)
        original.httpMethod = "PUT"
        original.setValue("Bearer abc", forHTTPHeaderField: "Authorization")
        original.httpBody = Data("payload".utf8)

        let restored = try #require(URLRequestArchive.unarchive(URLRequestArchive.archive(original)!))
        #expect(restored.url == original.url)
        #expect(restored.httpMethod == "PUT")
        #expect(restored.value(forHTTPHeaderField: "Authorization") == "Bearer abc")
        #expect(restored.httpBody == Data("payload".utf8))
    }

    @Test("InMemoryOfflineStore append / update / remove / removeAll")
    func inMemory() async {
        let store = InMemoryOfflineStore()
        let a = request("/a")
        var b = request("/b")
        await store.append(a)
        await store.append(b)
        #expect(await store.count == 2)

        b.attempts = 3
        await store.update(b)
        #expect(await store.all().first { $0.id == b.id }?.attempts == 3)

        await store.remove(a.id)
        #expect(await store.all().map(\.id) == [b.id])
        await store.removeAll()
        #expect(await store.count == 0)
    }

    @Test("FileOfflineStore persists across instances")
    func filePersists() async {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("nk-offline-\(UUID())/queue.json")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }

        let first = FileOfflineStore(fileURL: url)
        let req = request("/persisted")
        await first.append(req)

        let second = FileOfflineStore(fileURL: url)
        #expect(await second.all().map(\.id) == [req.id])
    }
}
