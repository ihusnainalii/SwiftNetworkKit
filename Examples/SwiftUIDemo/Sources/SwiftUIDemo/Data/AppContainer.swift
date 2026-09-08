import Foundation
import SwiftUI
import SwiftNetworkKit

/// Composition root. Builds the `NetworkClient` once and wires the concrete repositories.
/// Injected through the SwiftUI environment; swap `.live` for a stub container in previews/tests.
struct AppContainer: Sendable {
    let users: any UsersRepository
    let userContent: any UserContentRepository
    let composer: any PostComposer
    let diagnostics: any NetworkDiagnostics

    static let live: AppContainer = {
        let client = NetworkClient(
            configuration: NetworkConfiguration(
                baseURL: "https://jsonplaceholder.typicode.com",
                headers: ["Accept": "application/json"]
            )
        )
        return AppContainer(
            users: LiveUsersRepository(client: client),
            userContent: LiveUserContentRepository(client: client),
            composer: LivePostComposer(client: client),
            diagnostics: LiveNetworkDiagnostics(client: client)
        )
    }()
}

private struct AppContainerKey: EnvironmentKey {
    static let defaultValue = AppContainer.live
}

extension EnvironmentValues {
    var container: AppContainer {
        get { self[AppContainerKey.self] }
        set { self[AppContainerKey.self] = newValue }
    }
}
