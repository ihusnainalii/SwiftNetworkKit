import SwiftUI

struct DiagnosticsView: View {
    @State private var model: DiagnosticsViewModel

    init(container: AppContainer) {
        _model = State(wrappedValue: DiagnosticsViewModel(diagnostics: container.diagnostics))
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Client configuration") {
                    LabeledContent("Base URL", value: model.baseURL)
                    LabeledContent("Retry policy", value: model.retryPolicySummary)
                    ForEach(model.defaultHeaders, id: \.key) { header in
                        LabeledContent(header.key, value: header.value)
                    }
                }

                if !model.metrics.isEmpty {
                    Section("Metrics (live session)") {
                        ForEach(model.metrics) { row in
                            LabeledContent(row.label, value: row.value)
                        }
                    }
                }

                Section {
                    Button {
                        Task { await model.runAuthRefreshScenario() }
                    } label: {
                        if model.isRunning {
                            HStack { ProgressView(); Text("Running…") }
                        } else {
                            Label("Run 401 → refresh → retry", systemImage: "play.circle")
                        }
                    }
                    .disabled(model.isRunning)

                    ForEach(model.events) { event in
                        Label {
                            Text(event.message).font(.system(.callout, design: .monospaced))
                        } icon: {
                            Image(systemName: symbol(for: event.kind))
                                .foregroundStyle(color(for: event.kind))
                        }
                    }
                } header: {
                    Text("Automatic token refresh")
                } footer: {
                    Text("Runs against a mock transport so the flow is deterministic.")
                }
            }
            .navigationTitle("Diagnostics")
            .task { await model.refreshMetrics() }
            .refreshable { await model.refreshMetrics() }
        }
    }

    private func symbol(for kind: DiagnosticEvent.Kind) -> String {
        switch kind {
        case .info: "arrow.right.circle"
        case .success: "checkmark.circle.fill"
        case .warning: "arrow.triangle.2.circlepath"
        case .failure: "xmark.octagon.fill"
        }
    }

    private func color(for kind: DiagnosticEvent.Kind) -> Color {
        switch kind {
        case .info: .secondary
        case .success: .green
        case .warning: .orange
        case .failure: .red
        }
    }
}
