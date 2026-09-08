import Foundation
import SwiftNetworkKit

/// A tiny observable load-state holder for one async value.
///
/// This is the shape SwiftNetworkKit will ship as `NetworkResource` in milestone M14 — reproduced
/// here so the demo depends only on what's already released.
@MainActor
@Observable
final class Loadable<Value: Sendable> {

    enum Phase {
        case idle
        case loading
        case loaded(Value)
        case failed(NetworkError)
    }

    private(set) var phase: Phase = .idle

    var value: Value? {
        if case .loaded(let value) = phase { return value }
        return nil
    }

    var error: NetworkError? {
        if case .failed(let error) = phase { return error }
        return nil
    }

    var isLoading: Bool {
        if case .loading = phase { return true }
        return false
    }

    /// Runs `operation`, moving through `.loading` → `.loaded` / `.failed`.
    /// Call it from `.task { }` / `.refreshable { }` so SwiftUI owns cancellation.
    func load(_ operation: @Sendable () async throws -> Value) async {
        phase = .loading
        do {
            phase = .loaded(try await operation())
        } catch is CancellationError {
            // View went away — leave the last phase in place.
        } catch {
            phase = .failed(NetworkError.normalize(error))
        }
    }
}
