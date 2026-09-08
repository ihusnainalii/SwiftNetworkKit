import Foundation
import SwiftNetworkKit

/// Composition root. Builds the `NetworkClient` once and wires the concrete repositories.
/// Injected through the SwiftUI environment; swap `.live` for a stub container in previews/tests.
struct AppContainer: Sendable {
    let users: any UsersRepository
    let userContent: any UserContentRepository
    let composer: any PostComposer
    let diagnostics: any NetworkDiagnostics

    static let live: AppContainer = {
        let metrics = InMemoryMetrics()
        var configuration = NetworkConfiguration(
            baseURL: "https://jsonplaceholder.typicode.com",
            headers: ["Accept": "application/json"]
        )
        configuration.metrics = metrics
        configuration.requestInterceptors = [ClientHeaderInterceptor()]
        let client = NetworkClient(configuration: configuration)
        return AppContainer(
            users: LiveUsersRepository(client: client),
            userContent: LiveUserContentRepository(client: client),
            composer: LivePostComposer(client: client),
            diagnostics: LiveNetworkDiagnostics(client: client, metrics: metrics)
        )
    }()
}
