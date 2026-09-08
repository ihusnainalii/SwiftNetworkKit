import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("RequestDeduplicator")
struct RequestDeduplicatorTests {

    private actor Calls {
        private(set) var count = 0
        func bump() { count += 1 }
    }

    @Test("concurrent callers for the same key share one execution")
    func sharesExecution() async throws {
        let dedup = RequestDeduplicator()
        let calls = Calls()

        let results = try await withThrowingTaskGroup(of: Int.self) { group in
            for _ in 0..<5 {
                group.addTask {
                    try await dedup.result(for: "GET /thing") {
                        await calls.bump()
                        try await Task.sleep(for: .milliseconds(10))
                        return 42
                    }
                }
            }
            return try await group.reduce(into: [Int]()) { $0.append($1) }
        }

        #expect(results == Array(repeating: 42, count: 5))
        #expect(await calls.count == 1)
    }

    @Test("different keys execute independently")
    func differentKeys() async throws {
        let dedup = RequestDeduplicator()
        let calls = Calls()
        async let a = dedup.result(for: "GET /a") { await calls.bump(); return 1 }
        async let b = dedup.result(for: "GET /b") { await calls.bump(); return 2 }
        _ = try await (a, b)
        #expect(await calls.count == 2)
    }

    @Test("a failure reaches every waiting caller and the key is freed")
    func errorPropagates() async {
        let dedup = RequestDeduplicator()
        struct Boom: Error {}

        let first = Task { try await dedup.result(for: "k") {
            try await Task.sleep(for: .milliseconds(5)); throw Boom()
        } as Int }
        let second = Task { try await dedup.result(for: "k") {
            try await Task.sleep(for: .milliseconds(5)); throw Boom()
        } as Int }

        var thrown = 0
        for task in [first, second] {
            if case .failure(let error) = await task.result, error is Boom { thrown += 1 }
        }
        #expect(thrown == 2)
        #expect(await dedup.inFlightCount == 0)
    }
}
