import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("RequestQueue")
struct RequestQueueTests {

    private actor Meter {
        private(set) var current = 0
        private(set) var peak = 0
        func enter() { current += 1; peak = max(peak, current) }
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
        #expect(await meter.peak >= 2) // the limit was actually exercised
        #expect(await queue.runningCount == 0)
    }

    @Test("higher priority waiters are admitted before lower ones")
    func priorityOrder() async throws {
        let queue = RequestQueue(maxConcurrent: 1)
        let order = Order()

        // occupy the single slot
        let blocker = Task {
            try await queue.enqueue(priority: .normal) { try await Task.sleep(for: .milliseconds(40)) }
        }
        try await Task.sleep(for: .milliseconds(5))

        async let low: Void = queue.enqueue(priority: .low) { await order.record("low") }
        try await Task.sleep(for: .milliseconds(2))
        async let high: Void = queue.enqueue(priority: .high) { await order.record("high") }

        _ = try await (low, high)
        _ = try await blocker.value
        #expect(await order.entries == ["high", "low"])
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

private actor QueueCounter {
    private(set) var value = 0
    func increment() { value += 1 }
}
