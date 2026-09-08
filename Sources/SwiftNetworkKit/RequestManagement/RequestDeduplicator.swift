import Foundation

/// Collapses concurrent identical requests into one in-flight operation. Opt-in, and only ever used
/// for `GET`/`HEAD` — never for anything user-specific or side-effecting.
actor RequestDeduplicator {

    private var inFlight: [String: Task<any Sendable, any Error>] = [:]

    /// Runs `execute` for `key`, or — if an identical request is already running — awaits its result.
    func result<T: Sendable>(
        for key: String,
        execute: @escaping @Sendable () async throws -> T
    ) async throws -> T {
        if let existing = inFlight[key] {
            return try await requireSameType(existing.value)
        }

        let task = Task<any Sendable, any Error> { try await execute() }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        return try await requireSameType(task.value)
    }

    var inFlightCount: Int { inFlight.count }

    /// The stored `Task` is type-erased to `any Sendable`. Every caller sharing a key requests the
    /// same `T` (the key is derived from the endpoint), so a mismatch is a programmer error rather
    /// than a runtime condition — surface it as `.unknown` instead of trapping.
    private func requireSameType<T: Sendable>(_ value: any Sendable) throws -> T {
        guard let typed = value as? T else {
            throw NetworkError.unknown(underlying: nil)
        }
        return typed
    }
}
