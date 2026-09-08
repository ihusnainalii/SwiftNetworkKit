import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("RequestQueue")
struct RequestQueueTests {

    private actor Meter {
        private(set) var current = 0
        private(set) var peak = 0
        func enter() {
            current += 1
            peak = max(peak, current)
        }
        func exit() { current -= 1 }
    }

    @Test("never runs more than maxConcurrent at once")
    func concurrencyLimit() async throws {
        let queue = RequestQueue(maxConcurrent: 3)
        let meter = Meter()

        try await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<20 {
                group.addTask {
                    try await queue.enqueue(priority: .normal) {
                        await meter.enter()
                        try await Task.sleep(for: .milliseconds(5))
                        await meter.exit()
                    }
                }
            }
            try await group.waitForAll()
        }

        #expect(await meter.peak <= 3)
        #expect(await meter.peak >= 2)  // the limit was actually exercised
        #expect(await queue.runningCount == 0)
    }

    @Test("higher priority waiters are admitted before lower ones")
    func priorityOrder() async throws {
        let queue = RequestQueue(maxConcurrent: 1)
        let order = Order()
        let gate = Gate()

        // Occupy the single slot until the test opens the gate.
        let blocker = Task {
            try await queue.enqueue(priority: .normal) { await gate.wait() }
        }
        try await poll { await queue.runningCount == 1 }

        // Register the low-priority waiter, then the high-priority one, confirming each is
        // enqueued before adding the next so the outcome depends only on priority, not scheduling.
        async let low: Void = queue.enqueue(priority: .low) { await order.record("low") }
        try await poll { await queue.waitingCount == 1 }
        async let high: Void = queue.enqueue(priority: .high) { await order.record("high") }
        try await poll { await queue.waitingCount == 2 }

        await gate.open()
        _ = try await (low, high)
        _ = try await blocker.value
        #expect(await order.entries == ["high", "low"])
    }

    /// Spins on an actor-state condition (max ~1s) instead of a fixed sleep, so the test does not
    /// depend on scheduling latency (which balloons under ThreadSanitizer).
    private func poll(_ condition: @Sendable () async -> Bool) async throws {
        for _ in 0..<1000 {
            if await condition() { return }
            try await Task.sleep(for: .milliseconds(1))
        }
        Issue.record("poll condition never became true")
    }

    @Test("pause holds the queue; resume drains it")
    func pauseResume() async throws {
        let queue = RequestQueue(maxConcurrent: 2)
        await queue.pause()

        let done = QueueCounter()
        let tasks = (0..<4).map { _ in
            Task { try await queue.enqueue(priority: .normal) { await done.increment() } }
        }
        try await Task.sleep(for: .milliseconds(10))
        #expect(await done.value == 0)

        await queue.resume()
        for task in tasks { _ = try await task.value }
        #expect(await done.value == 4)
    }
}

private actor Order {
    private(set) var entries: [String] = []
    func record(_ s: String) { entries.append(s) }
}

/// A one-shot gate: `wait()` suspends until `open()` is called (or returns immediately if already open).
private actor Gate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var opened = false

    func wait() async {
        if opened { return }
        await withCheckedContinuation { continuation = $0 }
    }

    func open() {
        opened = true
        continuation?.resume()
        continuation = nil
    }
}

private actor QueueCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}
