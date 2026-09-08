import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("NetworkClient offline queue")
struct NetworkClientOfflineTests {

    private struct Ack: Codable, Sendable { let ok: Bool }
    private struct QueuedPost: Endpoint {
        typealias Response = Ack
        let path = "/submit"
        let method = HTTPMethod.post
        var offlineBehavior: OfflineBehavior { .queue(expiresAfter: nil) }
    }
    private struct PlainPost: Endpoint {
        typealias Response = Ack
        let path = "/submit"
        let method = HTTPMethod.post
    }

    private func client(
        _ transport: MockNetworkTransport,
        store: InMemoryOfflineStore,
        monitor: MockNetworkMonitor
    ) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.offlineStore = store
        config.networkMonitor = monitor
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("an offline .queue endpoint throws .offlineQueued and persists the request")
    func queuesWhenOffline() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.failure(.noInternet))
        let store = InMemoryOfflineStore()
        let c = client(transport, store: store, monitor: MockNetworkMonitor())

        let error = await #expect(throws: NetworkError.self) {
            try await c.request(QueuedPost())
        }
        guard case .offlineQueued(let id)? = error else { Issue.record("expected .offlineQueued"); return }
        #expect(await store.count == 1)
        #expect(await store.all().first?.id == id)
    }

    @Test("a plain endpoint just fails offline")
    func plainEndpointFailsOffline() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.failure(.noInternet))
        let store = InMemoryOfflineStore()
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport, store: store, monitor: MockNetworkMonitor()).request(PlainPost())
        }
        #expect(error?.code == .noInternet)
        #expect(await store.count == 0)
    }

    @Test("reconnecting replays the queued request and emits an event")
    func replaysOnReconnect() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.failure(.noInternet), .json(Data(#"{"ok":true}"#.utf8), status: 201))
        let store = InMemoryOfflineStore()
        let monitor = MockNetworkMonitor(initial: .unsatisfied)
        let c = client(transport, store: store, monitor: monitor)

        _ = try? await c.request(QueuedPost())
        #expect(await store.count == 1)

        let events = await c.offlineReplayEvents()
        async let first: OfflineReplayEvent? = {
            for await event in events { return event }
            return nil
        }()

        await monitor.send(.satisfied(.wifi))
        for _ in 0..<200 where await store.count != 0 { await Task.yield() }

        #expect(await store.count == 0)
        if case .replayed(_, let status)? = await first {
            #expect(status == 201)
        } else {
            Issue.record("expected .replayed event")
        }
    }
}
