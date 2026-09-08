/// Drives the "how does automatic 401 refresh work" walkthrough on the Diagnostics screen.
protocol NetworkDiagnostics: Sendable {
    var baseURL: String { get }
    var defaultHeaders: [String: String] { get }
    /// Human-readable summary of the client's retry policy (attempts + backoff).
    var retryPolicySummary: String { get }
    /// Human-readable summary of the client's SSL pinning configuration.
    var sslPinningSummary: String { get }
    /// Live connectivity, as label/value rows (status + link type).
    func connectivitySummary() async -> [MetricsRow]
    /// Live counters from the client's metrics sink, as label/value rows for display.
    func metricsSummary() async -> [MetricsRow]
    /// Emits one event per step of a mock 401 → refresh → retry flow.
    func runAuthRefreshScenario() -> AsyncStream<DiagnosticEvent>
}
