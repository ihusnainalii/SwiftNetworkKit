/// Drives the "how does automatic 401 refresh work" walkthrough on the Diagnostics screen.
protocol NetworkDiagnostics: Sendable {
    var baseURL: String { get }
    var defaultHeaders: [String: String] { get }
    /// Emits one event per step of a mock 401 → refresh → retry flow.
    func runAuthRefreshScenario() -> AsyncStream<DiagnosticEvent>
}
