import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("BackoffStrategy")
struct BackoffStrategyTests {

    @Test("exponential yields 0.5, 1, 2, 4, 8 with no jitter")
    func exponentialSequence() {
        let backoff = BackoffStrategy.exponential()
        let delays = (1...5).map { backoff.delay(forAttempt: $0, jitter: .none) }
        #expect(delays == [0.5, 1, 2, 4, 8])
    }

    @Test("exponential is capped at maxDelay")
    func exponentialCap() {
        let backoff = BackoffStrategy.exponential(base: 1, multiplier: 10, maxDelay: 30)
        #expect(backoff.delay(forAttempt: 1, jitter: .none) == 1)
        #expect(backoff.delay(forAttempt: 2, jitter: .none) == 10)
        #expect(backoff.delay(forAttempt: 3, jitter: .none) == 30) // 100 clamped
        #expect(backoff.delay(forAttempt: 9, jitter: .none) == 30)
    }

    @Test("constant ignores the attempt number")
    func constant() {
        let backoff = BackoffStrategy.constant(2.5)
        #expect(backoff.delay(forAttempt: 1, jitter: .none) == 2.5)
        #expect(backoff.delay(forAttempt: 7, jitter: .none) == 2.5)
    }

    @Test("full jitter stays within 0...delay, equal within delay/2...delay")
    func jitterBounds() {
        let raw = 8.0
        for _ in 0..<200 {
            #expect((0...raw).contains(Jitter.full.apply(to: raw)))
            #expect(((raw / 2)...raw).contains(Jitter.equal.apply(to: raw)))
        }
        #expect(Jitter.none.apply(to: raw) == raw)
        #expect(Jitter.full.apply(to: 0) == 0)
    }
}
