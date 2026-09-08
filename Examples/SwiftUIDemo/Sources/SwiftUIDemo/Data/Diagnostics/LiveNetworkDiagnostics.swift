import Foundation
import SwiftNetworkKit

/// Runs a deterministic 401 → refresh → retry against a `MockNetworkTransport` and narrates each step.
struct LiveNetworkDiagnostics: NetworkDiagnostics {
    let baseURL: String
    let defaultHeaders: [String: String]

    init(client: NetworkClient) {
        self.baseURL = client.configuration.environment.baseURL.absoluteString
        self.defaultHeaders = client.configuration.environment.defaultHeaders.dictionary
    }

    func runAuthRefreshScenario() -> AsyncStream<DiagnosticEvent> {
        AsyncStream { continuation in
            let emit: @Sendable (String, DiagnosticEvent.Kind) -> Void = { message, kind in
                continuation.yield(DiagnosticEvent(message: message, kind: kind))
            }

            let task = Task {
                struct Secret: Codable, Sendable { let value: String }
                struct SecretEndpoint: Endpoint {
                    typealias Response = Secret
                    let path = "/secret"
                    var authentication: AuthRequirement { .required }
                }

                let transport = MockNetworkTransport()
                transport.enqueue(
                    .success(status: 401, headers: [:], body: Data(#"{"message":"token expired"}"#.utf8)),
                    .json(Data(#"{"value":"the answer is 42"}"#.utf8))
                )

                emit("Request GET /secret with a stale bearer token", .info)
                let refreshes = RefreshCounter()

                let client = NetworkClient(
                    configuration: NetworkConfiguration(
                        baseURL: "https://api.example.com",
                        tokenStorage: InMemoryTokenStorage(seed: TokenPair(accessToken: "stale-token"))
                    ),
                    transport: transport,
                    refresh: { _ in
                        await refreshes.bump()
                        emit("↻ 401 received — TokenManager runs the refresh handler (single-flight)", .warning)
                        return TokenPair(accessToken: "fresh-token")
                    },
                    onSessionExpired: { emit("session expired — the app would log out here", .failure) }
                )

                do {
                    let secret = try await client.request(SecretEndpoint())
                    let tokens = transport.recordedRequests.compactMap { $0.value(forHTTPHeaderField: "Authorization") }
                    emit("Retried automatically with the new token", .info)
                    emit("Tokens sent to the server: \(tokens.joined(separator: "  →  "))", .info)
                    emit("Decoded response: \"\(secret.value)\" after \(await refreshes.count) refresh", .success)
                } catch {
                    emit("Failed: \(error)", .failure)
                }
                continuation.finish()
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }
}
