import Foundation

/// The production ``NetworkClock``: a thin wrapper over `ContinuousClock` and `Task.sleep`.
public struct ContinuousClockAdapter: NetworkClock {
    public init() {}

    public func now() -> ContinuousClock.Instant {
        ContinuousClock().now
    }

    public func sleep(for duration: Duration) async throws {
        try await Task.sleep(for: duration)
    }
}
