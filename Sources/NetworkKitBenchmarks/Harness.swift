import Foundation

/// A tiny, zero-dependency timing harness: warm up, run `iterations` timed passes, report the
/// distribution. Deliberately not statistically fancy — the goal is an honest order-of-magnitude
/// picture of SwiftNetworkKit's own overhead, published alongside each release.
enum Harness {
    /// Times a synchronous closure.
    static func measure(
        _ id: String,
        _ label: String,
        unit: BenchmarkResult.Unit,
        iterations: Int,
        warmup: Int = 200,
        note: String = "",
        _ body: () throws -> Void
    ) rethrows -> BenchmarkResult {
        for _ in 0..<warmup { try body() }
        var samples = [Double](repeating: 0, count: iterations)
        let clock = ContinuousClock()
        for i in 0..<iterations {
            let start = clock.now
            try body()
            samples[i] = Double(start.duration(to: clock.now).nanoseconds)
        }
        return BenchmarkResult(id: id, label: label, unit: unit, iterations: iterations, samples: samples, note: note)
    }

    /// Times an async closure (one `await` per iteration).
    static func measureAsync(
        _ id: String,
        _ label: String,
        unit: BenchmarkResult.Unit,
        iterations: Int,
        warmup: Int = 100,
        note: String = "",
        _ body: () async throws -> Void
    ) async rethrows -> BenchmarkResult {
        for _ in 0..<warmup { try await body() }
        var samples = [Double](repeating: 0, count: iterations)
        let clock = ContinuousClock()
        for i in 0..<iterations {
            let start = clock.now
            try await body()
            samples[i] = Double(start.duration(to: clock.now).nanoseconds)
        }
        return BenchmarkResult(id: id, label: label, unit: unit, iterations: iterations, samples: samples, note: note)
    }
}

extension Duration {
    fileprivate var nanoseconds: Int64 {
        let (s, attos) = components
        return s * 1_000_000_000 + attos / 1_000_000_000
    }
}
