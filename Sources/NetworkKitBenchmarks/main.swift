import Foundation
import SwiftNetworkKit

// Usage: swift run -c release NetworkKitBenchmarks [--out path/to/results.json]
//
// Prints the JSON report to stdout; also writes it to --out when given. Consumed by the
// SwiftNetworkKit-web site (Benchmarks/results.json in this repo, and a release asset).

let outPath: String? = {
    let args = CommandLine.arguments
    guard let i = args.firstIndex(of: "--out"), i + 1 < args.count else { return nil }
    return args[i + 1]
}()

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
    let swift = "6.\(0)"
    return .init(os: os, arch: arch, swift: swift, cpuCount: info.activeProcessorCount, configuration: config)
}

FileHandle.standardError.write(
    Data("Running SwiftNetworkKit benchmarks (\(currentEnvironment().configuration))...\n".utf8))

let results = await Scenarios.all()

let report = BenchmarkReport(
    version: SwiftNetworkKit.version,
    generatedAt: ISO8601DateFormatter().string(from: Date()),
    environment: currentEnvironment(),
    results: results
)

let encoder = JSONEncoder()
encoder.outputFormatting = [.prettyPrinted, .sortedKeys, .withoutEscapingSlashes]
let json = try encoder.encode(report)

if let outPath {
    try json.write(to: URL(fileURLWithPath: outPath))
    FileHandle.standardError.write(Data("Wrote \(results.count) results to \(outPath)\n".utf8))
}
print(String(decoding: json, as: UTF8.self))
