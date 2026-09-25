import Foundation

/// Bounds how many requests run at once and orders the waiting ones by ``RequestPriority``.
/// Best-effort: a running request is never preempted, and `pause()` doesn't cancel running work.
actor RequestQueue {

    private struct Waiter {
        let id: UInt64
        let priority: RequestPriority
        let continuation: CheckedContinuation<Void, any Error>
    }

    private let maxConcurrent: Int
    private var running = 0
    private var paused = false
    private var waiters: [Waiter] = []
    private var nextWaiterID: UInt64 = 0

    init(maxConcurrent: Int) {
        self.maxConcurrent = max(1, maxConcurrent)
    }

    /// Runs `operation` once a slot is free. A task cancelled while it waits leaves the queue at
    /// once, without ever taking a slot or running, and throws ``NetworkError/cancelled``.
    func enqueue<T: Sendable>(
        priority: RequestPriority,
        _ operation: @Sendable () async throws -> T
    ) async throws -> T {
        try await acquire(priority: priority)
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

    private func acquire(priority: RequestPriority) async throws {
        if Task.isCancelled { throw NetworkError.cancelled }
        if !paused, running < maxConcurrent {
            running += 1
            return
        }
        let id = nextWaiterID
        nextWaiterID += 1
        try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                // Cancellation can land before the waiter is registered; `cancelWaiter` would then find
                // nothing, so check here (this closure runs on the actor, before it can run).
                if Task.isCancelled {
                    continuation.resume(throwing: NetworkError.cancelled)
                    return
                }
                // Higher priority goes ahead of lower; equal priority keeps FIFO order.
                let index = waiters.firstIndex { $0.priority < priority } ?? waiters.count
                waiters.insert(Waiter(id: id, priority: priority, continuation: continuation), at: index)
            }
        } onCancel: {
            Task { await self.cancelWaiter(id) }
        }
        // `running` was already incremented by `drain()` before it resumed us.
    }

    private func cancelWaiter(_ id: UInt64) {
        guard let index = waiters.firstIndex(where: { $0.id == id }) else { return }
        waiters.remove(at: index).continuation.resume(throwing: NetworkError.cancelled)
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
