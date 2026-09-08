import Foundation

/// How much randomness to fold into a computed backoff delay, so a fleet of clients that all failed
/// at the same moment don't retry in lockstep.
public enum Jitter: Sendable, Hashable {
    /// No randomness — the raw delay. Use in tests for deterministic sequences.
    case none
    /// Uniform in `0...delay` (AWS "full jitter").
    case full
    /// Half the delay plus uniform `0...(delay/2)` (AWS "equal jitter").
    case equal

    /// Applies the jitter to a non-negative delay.
    public func apply(to delay: TimeInterval) -> TimeInterval {
        let d = max(0, delay)
        guard d > 0 else { return 0 }
        switch self {
        case .none: return d
        case .full: return .random(in: 0...d)
        case .equal: return d / 2 + .random(in: 0...(d / 2))
        }
    }
}
