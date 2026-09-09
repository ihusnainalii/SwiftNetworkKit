import Foundation

/// One benchmark's outcome. `samples` are raw nanoseconds; the encoded form carries the summary
/// statistics the website renders, converted to `unit`.
struct BenchmarkResult: Sendable {
    enum Unit: String, Codable, Sendable {
        case nanoseconds = "ns/op"
        case microseconds = "µs/op"
        case milliseconds = "ms/op"
        case ratio = "x"
        case count = "count"

        var perNanosecond: Double {
            switch self {
            case .nanoseconds: 1
            case .microseconds: 1.0 / 1_000
            case .milliseconds: 1.0 / 1_000_000
            case .ratio, .count: 1
            }
        }
    }

    let id: String
    let label: String
    let unit: Unit
    let iterations: Int
    let samples: [Double]
    var note: String = ""
    /// Set for derived results (dedup ratio, speed-up) that aren't a timed distribution.
    var scalar: Double?
}

extension BenchmarkResult: Encodable {
    enum CodingKeys: String, CodingKey {
        case id, label, unit, iterations, note, min, median, p90, p99, mean, stddev, value
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(label, forKey: .label)
        try c.encode(unit, forKey: .unit)
        try c.encode(iterations, forKey: .iterations)
        if !note.isEmpty { try c.encode(note, forKey: .note) }

        if let scalar {
            try c.encode(round(scalar * 100) / 100, forKey: .value)
            return
        }
        let sorted = samples.sorted()
        let k = unit.perNanosecond
        func q(_ f: Double) -> Double {
            sorted.isEmpty ? 0 : sorted[min(sorted.count - 1, Int(f * Double(sorted.count)))]
        }
        let mean = sorted.isEmpty ? 0 : sorted.reduce(0, +) / Double(sorted.count)
        let variance = sorted.isEmpty ? 0 : sorted.reduce(0) { $0 + ($1 - mean) * ($1 - mean) } / Double(sorted.count)
        func r(_ v: Double) -> Double { (v * k * 1000).rounded() / 1000 }
        try c.encode(r(sorted.first ?? 0), forKey: .min)
        try c.encode(r(q(0.5)), forKey: .median)
        try c.encode(r(q(0.9)), forKey: .p90)
        try c.encode(r(q(0.99)), forKey: .p99)
        try c.encode(r(mean), forKey: .mean)
        try c.encode(r(variance.squareRoot()), forKey: .stddev)
    }
}

/// The published document: `Benchmarks/results.json` in the repo and a release asset.
struct BenchmarkReport: Encodable, Sendable {
    struct Environment: Encodable, Sendable {
        let os: String
        let arch: String
        let swift: String
        let cpuCount: Int
        let configuration: String
    }

    let package = "SwiftNetworkKit"
    let version: String
    let generatedAt: String
    let environment: Environment
    let results: [BenchmarkResult]
}
