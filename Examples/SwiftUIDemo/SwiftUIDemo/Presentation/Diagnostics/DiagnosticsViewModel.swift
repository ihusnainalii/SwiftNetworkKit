import Foundation
import Observation

@MainActor
@Observable
final class DiagnosticsViewModel {
    private let diagnostics: any NetworkDiagnostics

    private(set) var events: [DiagnosticEvent] = []
    private(set) var isRunning = false

    init(diagnostics: any NetworkDiagnostics) {
        self.diagnostics = diagnostics
    }

    var baseURL: String { diagnostics.baseURL }
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
