import Foundation
import Observation

@MainActor
@Observable
final class DiagnosticsViewModel {
    private let diagnostics: any NetworkDiagnostics

    private(set) var events: [DiagnosticEvent] = []
    private(set) var isRunning = false
    private(set) var metrics: [MetricsRow] = []

    init(diagnostics: any NetworkDiagnostics) {
        self.diagnostics = diagnostics
    }

    var baseURL: String { diagnostics.baseURL }
    var retryPolicySummary: String { diagnostics.retryPolicySummary }
    var sslPinningSummary: String { diagnostics.sslPinningSummary }

    func refreshMetrics() async {
        metrics = await diagnostics.metricsSummary()
    }
    var defaultHeaders: [(key: String, value: String)] {
        diagnostics.defaultHeaders.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
    }

    func runAuthRefreshScenario() async {
        guard !isRunning else { return }
        isRunning = true
        events = []
        defer { isRunning = false }

        for await event in diagnostics.runAuthRefreshScenario() {
            events.append(event)
        }
    }
}
