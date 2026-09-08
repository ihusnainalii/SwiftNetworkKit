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
            return try await existing.value as! T
        }

        let task = Task<any Sendable, any Error> { try await execute() }
        inFlight[key] = task
        defer { inFlight[key] = nil }

        return try await task.value as! T
    }

    var inFlightCount: Int { inFlight.count }
}
