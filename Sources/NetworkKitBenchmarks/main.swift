import Foundation
import SwiftNetworkKit

// Usage: swift run -c release NetworkKitBenchmarks [--out results.json] [--traces traces.json]
//
// --out     writes the timed benchmark report (also printed to stdout)
// --traces  writes the pipeline + concurrency traces (real requests, timestamped per stage)
//
// Consumed by the SwiftNetworkKit-web site (committed copies in this repo + release assets).

func argValue(_ name: String) -> String? {
    let args = CommandLine.arguments
    guard let i = args.firstIndex(of: name), i + 1 < args.count else { return nil }
    return args[i + 1]
}

func currentEnvironment() -> BenchmarkReport.Environment {
    let info = ProcessInfo.processInfo
    let v = info.operatingSystemVersion
    #if os(macOS)
    let os = "macOS \(v.majorVersion).\(v.minorVersion).\(v.patchVersion)"
    #elseif os(Linux)
    let os = "Linux"
    #else
    let os = info.operatingSystemVersionString
    #endif
    #if arch(arm64)
    let arch = "arm64"
    #elseif arch(x86_64)
    let arch = "x86_64"
    #else
    let arch = "unknown"
    #endif
    #if DEBUG
    let config = "debug"
    #else
    let config = "release"
    #endif
    return .init(os: os, arch: arch, swift: "6", cpuCount: info.activeProcessorCount, configuration: config)
}

let env = currentEnvironment()
let now = ISO8601DateFormatter().string(from: Date())
let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]

func log(_ s: String) { FileHandle.standardError.write(Data((s + "\n").utf8)) }

log("SwiftNetworkKit benchmarks — \(env.configuration) build, \(env.os) \(env.arch)")

let report = BenchmarkReport(
    version: SwiftNetworkKit.version,
    generatedAt: now,
    environment: env,
    results: await Scenarios.all()
)
let reportJSON = try encoder.encode(report)
if let out = argValue("--out") {
    try reportJSON.write(to: URL(fileURLWithPath: out))
    log("wrote \(report.results.count) results -> \(out)")
}

if let tracesOut = argValue("--traces") {
    let traces = TraceReport(
        version: SwiftNetworkKit.version,
        generatedAt: now,
        environment: env,
        pipelines: await Traces.pipelines(version: SwiftNetworkKit.version),
        concurrency: await Traces.concurrency()
    )
    try encoder.encode(traces).write(to: URL(fileURLWithPath: tracesOut))
    log("wrote \(traces.pipelines.count) pipeline + \(traces.concurrency.count) concurrency traces -> \(tracesOut)")
}

print(String(decoding: reportJSON, as: UTF8.self))
