import SwiftUI

/// Renders any `LoadPhase` uniformly: spinner → content → error.
struct PhaseView<Value: Sendable, Content: View>: View {
    let phase: LoadPhase<Value>
    let retry: () -> Void
    @ViewBuilder let content: (Value) -> Content

    var body: some View {
        switch phase {
        case .idle, .loading:
            ProgressView().frame(maxWidth: .infinity, maxHeight: .infinity)
        case .loaded(let value):
            content(value)
        case .failed(let error):
            ErrorStateView(error: error, retry: retry)
        }
    }
}
