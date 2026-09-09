import Foundation

/// A ``NetworkClock`` for tests. `sleep(for:)` returns immediately (after a cooperative yield) and
/// records the requested duration; `now()` reports virtual time advanced by every recorded sleep.
///
/// A retry test therefore runs in microseconds and asserts on ``recordedSleeps`` instead of a
/// stopwatch. Cancellation is still honored: `sleep` throws `CancellationError` if the task is
/// cancelled, exactly like the real clock.
///
/// ponytail: instant recording clock, not a virtual scheduler. If a milestone needs a sleeper to
/// actually suspend until time is moved forward, add a blocking `advance(by:)` then.
@_spi(SwiftNetworkKitTesting) public final class TestClock: NetworkClock, @unchecked Sendable {

    private let lock = NSLock()
    private var _sleeps: [TimeInterval] = []
    private var _virtualElapsed: TimeInterval = 0
    private let origin = ContinuousClock().now

    @_spi(SwiftNetworkKitTesting) public init() {}

    /// Every `sleep(for:)` duration seen so far, in seconds, in order.
    @_spi(SwiftNetworkKitTesting) public var recordedSleeps: [TimeInterval] {
        lock.withLock { _sleeps }
    }

    /// Sum of all recorded sleeps — the virtual time that has "passed".
    @_spi(SwiftNetworkKitTesting) public var virtualElapsed: TimeInterval {
        lock.withLock { _virtualElapsed }
    }

    @_spi(SwiftNetworkKitTesting) public func now() -> ContinuousClock.Instant {
        origin.advanced(by: .seconds(virtualElapsed))
    }

    @_spi(SwiftNetworkKitTesting) public func sleep(for duration: Duration) async throws {
        try Task.checkCancellation()
        let seconds = duration.inSeconds
        lock.withLock {
            _sleeps.append(seconds)
            _virtualElapsed += seconds
        }
        await Task.yield()
    }
}

extension Duration {
    fileprivate var inSeconds: TimeInterval {
        let (seconds, attoseconds) = components
        return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
    }
}
