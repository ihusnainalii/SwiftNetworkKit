import Foundation
import SwiftNetworkKit

/// Runs a deterministic 401 → refresh → retry against a `MockNetworkTransport` and narrates each step.
struct LiveNetworkDiagnostics: NetworkDiagnostics {
    let baseURL: String
    let defaultHeaders: [String: String]
    let retryPolicySummary: String
    let sslPinningSummary: String
    let cacheSummary: String
    private let metrics: InMemoryMetrics
    private let monitor: any NetworkMonitor

    init(client: NetworkClient, metrics: InMemoryMetrics, monitor: any NetworkMonitor) {
        self.monitor = monitor
        self.baseURL = client.configuration.environment.baseURL.absoluteString
        self.defaultHeaders = client.configuration.environment.defaultHeaders.dictionary
        self.metrics = metrics
        switch client.configuration.sslPinning {
        case .disabled: self.sslPinningSummary = "disabled (system TLS)"
        case .certificates: self.sslPinningSummary = "certificate pinning"
        case .certificateResources: self.sslPinningSummary = "certificate pinning (bundle)"
        case .publicKeys: self.sslPinningSummary = "public-key pinning"
        case .development: self.sslPinningSummary = "record-only (development)"
        }
        let retry = client.configuration.retry
        let backoff: String
        switch retry.backoff {
        case .constant(let seconds): backoff = "constant \(seconds)s"
        case .exponential(let base, let multiplier, let maxDelay):
            backoff = "exponential \(base)s ×\(Int(multiplier)) (max \(Int(maxDelay))s)"
        }
        self.retryPolicySummary = "\(retry.maxAttempts) attempts, \(backoff)"

        let cache = client.configuration.cache
        if cache.store == nil {
            self.cacheSummary = "disabled"
        } else {
            self.cacheSummary = "\(cache.defaultPolicy), TTL \(Int(cache.defaultTTL))s"
        }
    }

    func connectivitySummary() async -> [MetricsRow] {
        let status = await monitor.currentStatus
        let state: String
        switch status {
        case .satisfied: state = "online"
        case .unsatisfied: state = "offline"
        case .requiresConnection: state = "checking..."
        }
        return [
            MetricsRow(label: "Status", value: state),
            MetricsRow(label: "Link", value: status.connectionType.map { "\($0)" } ?? "n/a"),
        ]
    }

    func metricsSummary() async -> [MetricsRow] {
        let snapshot = await metrics.snapshot()
        let averageMS = Int(snapshot.averageDuration.components.seconds * 1000)
            + Int(snapshot.averageDuration.components.attoseconds / 1_000_000_000_000_000)
        return [
            MetricsRow(label: "Requests", value: "\(snapshot.requestCount)"),
            MetricsRow(label: "Succeeded", value: "\(snapshot.successCount)"),
            MetricsRow(label: "Failed", value: "\(snapshot.failureCount)"),
            MetricsRow(label: "Retries", value: "\(snapshot.retryCount)"),
            MetricsRow(label: "Avg duration", value: "\(averageMS) ms"),
        ]
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
