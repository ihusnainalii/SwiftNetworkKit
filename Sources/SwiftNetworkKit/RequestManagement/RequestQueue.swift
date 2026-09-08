import Foundation

/// Bounds how many requests run at once and orders the waiting ones by ``RequestPriority``.
/// Best-effort: a running request is never preempted, and `pause()` doesn't cancel running work.
actor RequestQueue {

    private let maxConcurrent: Int
    private var running = 0
    private var paused = false
    private var waiters: [(priority: RequestPriority, continuation: CheckedContinuation<Void, Never>)] = []

    init(maxConcurrent: Int) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    /// Runs `operation` once a slot is free. A cancelled task still waits its turn, then throws
    /// ``NetworkError/cancelled`` without running.
    func enqueue<T: Sendable>(
        priority: RequestPriority,
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        await acquire(priority: priority)
        defer { release() }
        if Task.isCancelled { throw NetworkError.cancelled }
        return try await operation()
    }

    func pause() { paused = true }

    func resume() {
        paused = false
        drain()
    }

    /// Slots in use right now (test/inspection).
    var runningCount: Int { running }
    var waitingCount: Int { waiters.count }

    // MARK: - Internals

    private func acquire(priority: RequestPriority) async {
        if !paused, running < maxConcurrent {
            running += 1
            return
        }
        await withCheckedContinuation { continuation in
            // Higher priority goes ahead of lower; equal priority keeps FIFO order.
            let index = waiters.firstIndex { $0.priority < priority } ?? waiters.count
            waiters.insert((priority, continuation), at: index)
        }
        // `running` was already incremented by `drain()` before it resumed us.
    }

    private func release() {
        running -= 1
        drain()
    }

    private func drain() {
        while !paused, running < maxConcurrent, !waiters.isEmpty {
            let waiter = waiters.removeFirst()
            running += 1
            waiter.continuation.resume()
        }
    }
}
