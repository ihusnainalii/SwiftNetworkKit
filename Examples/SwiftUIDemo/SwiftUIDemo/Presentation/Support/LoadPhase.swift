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
