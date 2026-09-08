import Foundation
import SwiftNetworkKit

/// Composition root. Builds the `NetworkClient` once and wires the concrete repositories.
/// Injected through the SwiftUI environment; swap `.live` for a stub container in previews/tests.
struct AppContainer: Sendable {
    let users: any UsersRepository
    let userContent: any UserContentRepository
    let composer: any PostComposer
    let diagnostics: any NetworkDiagnostics
    let media: any MediaDownloader

    static let live: AppContainer = {
        let metrics = InMemoryMetrics()
        var configuration = NetworkConfiguration(
            baseURL: "https://jsonplaceholder.typicode.com",
            headers: ["Accept": "application/json"]
        )
        configuration.metrics = metrics
        configuration.requestInterceptors = [ClientHeaderInterceptor()]
        // GET responses (users, posts, todos, albums) are served from cache first, then revalidated.
        configuration.cache = CacheConfiguration(
            store: MemoryCacheStore(limitBytes: 8 * 1024 * 1024),
            defaultPolicy: .cacheFirst,
            defaultTTL: 120
        )
        configuration.maxConcurrentRequests = 4
        configuration.enableDeduplication = true
        let monitor = PathNetworkMonitor()
        let offlineStore = InMemoryOfflineStore()
        configuration.networkMonitor = monitor
        configuration.offlineStore = offlineStore
        let client = NetworkClient(configuration: configuration)
        return AppContainer(
            users: LiveUsersRepository(client: client),
            userContent: LiveUserContentRepository(client: client),
            composer: LivePostComposer(client: client),
            diagnostics: LiveNetworkDiagnostics(client: client, metrics: metrics, monitor: monitor, offlineStore: offlineStore),
            media: LiveMediaDownloader(client: client)
        )
    }()
}
