import Foundation
import Testing

/// Grep-style guards on the library's own discipline. They scan `Sources/SwiftNetworkKit/` so a
/// regression (a stray `import SwiftUI`, an unguarded platform import, a `print` in the pipeline)
/// fails CI instead of shipping.
@Suite("Architecture")
struct ArchitectureTests {

    private static let sourceRoot: URL = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
        .appendingPathComponent("Sources/SwiftNetworkKit")

    /// Every `.swift` file as (relative name, code lines with `//`-comment lines removed).
    private func sources() throws -> [(name: String, codeLines: [String])] {
        let enumerator = FileManager.default.enumerator(at: Self.sourceRoot, includingPropertiesForKeys: nil)
        var out: [(String, [String])] = []
        while let url = enumerator?.nextObject() as? URL {
            guard url.pathExtension == "swift" else { continue }
            let text = try String(contentsOf: url, encoding: .utf8)
            let name = url.path.replacingOccurrences(of: Self.sourceRoot.path + "/", with: "")
            let code = text
                .split(separator: "\n", omittingEmptySubsequences: false)
                .map(String.init)
                .filter { !$0.trimmingCharacters(in: .whitespaces).hasPrefix("//") }
            out.append((name, code))
        }
        return out
    }

    @Test("the library never imports SwiftUI (that belongs in a consuming app)")
    func noSwiftUI() throws {
        for file in try sources() where file.codeLines.contains(where: { $0.trimmingCharacters(in: .whitespaces) == "import SwiftUI" }) {
            Issue.record("\(file.name) imports SwiftUI")
        }
    }

    @Test("platform frameworks are #if canImport-guarded")
    func guardedPlatformImports() throws {
        let guarded = ["Security", "Network", "CryptoKit", "os"]
        for file in try sources() {
            let joined = file.codeLines.joined(separator: "\n")
            for framework in guarded {
                let importsIt = file.codeLines.contains { $0.trimmingCharacters(in: .whitespaces) == "import \(framework)" }
                guard importsIt else { continue }
                if !joined.contains("#if canImport(\(framework))") {
                    Issue.record("\(file.name): `import \(framework)` without a `#if canImport(\(framework))` guard")
                }
            }
        }
    }

    @Test("no print() in the shipping library (logging goes through NetworkLogger)")
    func noPrint() throws {
        for file in try sources() where file.name != "Logging/ConsoleNetworkLogger.swift" {
            for line in file.codeLines
            where line.range(of: #"(?<![A-Za-z0-9_.])print\("#, options: .regularExpression) != nil {
                Issue.record("\(file.name) calls print(): \(line.trimmingCharacters(in: .whitespaces))")
            }
        }
    }

    @Test("no try! in the request pipeline")
    func noForceTryInPipeline() throws {
        let pipeline: Set = ["Core/NetworkClient.swift", "Core/NetworkClient+Upload.swift",
                             "Core/NetworkClient+Pagination.swift", "HTTP/RequestBuilder.swift"]
        for file in try sources() where pipeline.contains(file.name) {
            for line in file.codeLines where line.contains("try!") {
                Issue.record("\(file.name) uses try!")
            }
        }
    }
}
