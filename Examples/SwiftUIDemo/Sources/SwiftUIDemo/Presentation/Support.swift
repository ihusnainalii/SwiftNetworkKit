import SwiftUI
import SwiftNetworkKit

/// Load state for one async value. Mirrors the `NetworkResource` shape SwiftNetworkKit ships in M14.
enum LoadPhase<Value: Sendable>: Sendable {
    case idle
    case loading
    case loaded(Value)
    case failed(NetworkError)

    var value: Value? {
        if case .loaded(let value) = self { return value }
        return nil
    }

    var isLoading: Bool {
        if case .loading = self { return true }
        return false
    }
}

extension LoadPhase {
    /// Runs `operation` and returns the resulting phase, keeping `previousValue` visible on cancel.
    static func run(
        previousValue: Value?,
        _ operation: @Sendable () async throws -> Value
    ) async -> LoadPhase {
        do {
            return .loaded(try await operation())
        } catch is CancellationError {
            return previousValue.map(LoadPhase.loaded) ?? .idle
        } catch {
            return .failed(NetworkError.normalize(error))
        }
    }
}

/// Full-bleed error state with retry, driven by a `NetworkError`.
struct ErrorStateView: View {
    let error: NetworkError
    let retry: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("Something went wrong", systemImage: symbol)
        } description: {
            Text(error.localizedDescription)
        } actions: {
            Button("Try Again", action: retry).buttonStyle(.borderedProminent)
        }
    }

    private var symbol: String {
        switch error.code {
        case .noInternet, .offline: "wifi.slash"
        case .timeout: "clock.badge.exclamationmark"
        case .notFound: "questionmark.folder"
        case .unauthorized, .forbidden, .sessionExpired: "lock.trianglebadge.exclamationmark"
        case .server, .rateLimited: "exclamationmark.icloud"
        default: "exclamationmark.triangle"
        }
    }
}

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
