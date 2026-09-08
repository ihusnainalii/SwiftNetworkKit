import Foundation

/// Computes how long to wait before the next retry attempt.
public enum BackoffStrategy: Sendable, Hashable {
    /// The same delay before every retry.
    case constant(TimeInterval)
    /// `base * multiplier^(attempt - 1)`, capped at `maxDelay`.
    case exponential(base: TimeInterval = 0.5, multiplier: Double = 2, maxDelay: TimeInterval = 30)

    /// The delay to wait after `attempt` (1-indexed: `attempt` is the try that just failed), with
    /// `jitter` applied.
    ///
    /// `exponential()` yields `0.5, 1, 2, 4, 8, …` for attempts `1, 2, 3, …` with `jitter: .none`.
    public func delay(forAttempt attempt: Int, jitter: Jitter = .none) -> TimeInterval {
        let raw: TimeInterval
        switch self {
        case .constant(let value):
            raw = max(0, value)
        case .exponential(let base, let multiplier, let maxDelay):
            let exponent = Double(max(0, attempt - 1))
            raw = min(maxDelay, max(0, base) * pow(multiplier, exponent))
        }
        return jitter.apply(to: raw)
    }
}
