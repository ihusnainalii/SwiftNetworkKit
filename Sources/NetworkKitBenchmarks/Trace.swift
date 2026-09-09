import Foundation

/// A real request walked through the pipeline once, with a wall-clock timestamp captured at each
/// stage the public hooks expose (request interceptors, transport in/out, response interceptors,
/// return). The website's "Request Lifecycle" view replays these instead of a hand-written script.
struct PipelineTrace: Encodable, Sendable {
    struct Stage: Encodable, Sendable {
        let name: String
        let startMicros: Double
        let durationMicros: Double
        let detail: String
    }
    let id: String
    let label: String
    let note: String
    let totalMicros: Double
    let stages: [Stage]
}

/// Several real requests run concurrently, with each lane's events timestamped. The "Concurrency
/// Visualizer" replays these: which requests coalesced, when the single refresh fired, admission order.
struct ConcurrencyTrace: Encodable, Sendable {
    struct Event: Encodable, Sendable {
        let atMicros: Double
        let kind: String
        let note: String
    }
    struct Lane: Encodable, Sendable {
        let name: String
        let events: [Event]
    }
    let id: String
    let label: String
    let summary: String
    let lanes: [Lane]
}

struct TraceReport: Encodable, Sendable {
    let package = "SwiftNetworkKit"
    let version: String
    let generatedAt: String
    let environment: BenchmarkReport.Environment
    let pipelines: [PipelineTrace]
    let concurrency: [ConcurrencyTrace]
}

/// A minimal thread-safe counter (Swift 6.1 has no `Mutex`).
final class Counter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() { lock.withLock { value += 1 } }
    var current: Int { lock.withLock { value } }
}

/// Collects `(elapsedMicros, kind, note)` events against a fixed start instant. Thread-safe.
final class TraceRecorder: @unchecked Sendable {
    private let lock = NSLock()
    private let start = ContinuousClock().now
    private var events: [(t: Double, lane: String, kind: String, note: String)] = []

    func mark(_ lane: String, _ kind: String, _ note: String = "") {
        let c = start.duration(to: ContinuousClock().now).components
        let micros = Double(c.seconds) * 1_000_000 + Double(c.attoseconds) / 1_000_000_000_000
        lock.withLock { events.append((micros, lane, kind, note)) }
    }

    var ordered: [(t: Double, lane: String, kind: String, note: String)] {
        lock.withLock { events.sorted { $0.t < $1.t } }
    }
}
