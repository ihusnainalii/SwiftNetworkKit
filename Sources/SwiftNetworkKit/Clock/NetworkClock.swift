import Foundation

/// The time port. Every wait in the library — retry backoff, `Retry-After`, proactive token
/// refresh — goes through this so tests can drive them with a fake clock instead of real delays.
///
/// Default: ``ContinuousClockAdapter``. Tests: `TestClock` (in the `Testing/` folder).
public protocol NetworkClock: Sendable {
    /// The current instant on a monotonic clock (unaffected by wall-clock changes).
    func now() -> ContinuousClock.Instant

    /// Suspends for `duration`. Throws `CancellationError` if the task is cancelled while waiting —
    /// callers map that to ``NetworkError/cancelled``.
    func sleep(for duration: Duration) async throws
}
