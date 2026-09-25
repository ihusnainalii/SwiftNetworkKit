#if canImport(Observation)
import Foundation
import Observation

/// An observable load-state holder for one endpoint's response. Drop it in a SwiftUI view's `@State`
/// and drive it from `.task`.
///
/// ```swift
/// @State private var users = NetworkResource<[User]>(client: .live)
///
/// var body: some View {
///     List(users.value ?? []) { ... }
///         .overlay { if users.isLoading { ProgressView() } }
///         .task { await users.load(ListUsers()) }
/// }
/// ```
///
/// A new ``load(_:)`` cancels the previous request, and cancelling the task that called `load` (for
/// example when a `.task` ends) cancels its request. A cancelled load never shows as a failure.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
@MainActor
@Observable
public final class NetworkResource<Value: Sendable> {

    public enum Phase: Sendable {
        case idle
        case loading
        case loaded(Value)
        case failed(NetworkError)
    }

    public private(set) var phase: Phase = .idle

    private let client: NetworkClient
    private var task: Task<Void, Never>?
    private var reloadAction: (@Sendable () async -> Void)?

    public init(client: NetworkClient) {
        self.client = client
    }

    public var value: Value? {
        if case .loaded(let value) = phase { return value }
        return nil
    }

    public var error: NetworkError? {
        if case .failed(let error) = phase { return error }
        return nil
    }

    public var isLoading: Bool {
        if case .loading = phase { return true }
        return false
    }

    /// Loads `endpoint`, cancelling any request already in flight. Keeps the last value visible while
    /// reloading.
    public func load<E: Endpoint>(_ endpoint: E) async where E.Response == Value {
        task?.cancel()
        reloadAction = { [weak self] in await self?.load(endpoint) }
        if value == nil { phase = .loading }

        let client = client
        let work = Task { @MainActor [weak self] in
            do {
                let response = try await client.request(endpoint)
                self?.phase = .loaded(response)
            } catch {
                let mapped = NetworkError.normalize(error)
                // Superseded or cancelled: leave the previous phase in place.
                if mapped.code != .cancelled { self?.phase = .failed(mapped) }
            }
        }
        task = work
        await withTaskCancellationHandler {
            await work.value
        } onCancel: {
            work.cancel()
        }
    }

    /// Re-runs the last ``load(_:)``.
    public func reload() async {
        await reloadAction?()
    }
}
#endif
