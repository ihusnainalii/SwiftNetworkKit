import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("Pagination")
struct PaginationTests {

    private struct Chunk: Codable, Sendable { let values: [Int] }

    private struct Pages: PaginatedEndpoint {
        typealias Response = Chunk
        var page = 1
        var path: String { "/numbers" }
        var queryParameters: QueryParameters? { ["page": .int(page)] }

        func items(from response: Chunk) -> [Int] { response.values }
        func nextPage(after response: Chunk) -> Pages? {
            response.values.isEmpty ? nil : Pages(page: page + 1)
        }
    }

    /// Ignores `nextPage` termination and keeps going — for the runaway-server cap test.
    private struct Runaway: PaginatedEndpoint {
        typealias Response = Chunk
        var page = 1
        var path: String { "/forever" }
        var queryParameters: QueryParameters? { ["page": .int(page)] }
        func items(from response: Chunk) -> [Int] { response.values }
        func nextPage(after response: Chunk) -> Runaway? { Runaway(page: page + 1) }
    }

    private func client(_ transport: MockNetworkTransport) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("streams each page then finishes")
    func streamsPages() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"{"values":[1,2]}"#.utf8)),
            .json(Data(#"{"values":[3,4]}"#.utf8)),
            .json(Data(#"{"values":[]}"#.utf8))
        )
        var pages: [[Int]] = []
        for try await page in client(transport).paginate(Pages()) {
            pages.append(page)
        }
        #expect(pages == [[1, 2], [3, 4], []])
        #expect(transport.requestCount == 3)
        // page query parameter incremented
        #expect(transport.recordedRequests.map { $0.url!.query } == ["page=1", "page=2", "page=3"])
    }

    @Test("collectAll flattens; max truncates and stops early")
    func collectAll() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"{"values":[1,2]}"#.utf8)),
            .json(Data(#"{"values":[3,4]}"#.utf8)),
            .json(Data(#"{"values":[5,6]}"#.utf8)),
            .json(Data(#"{"values":[]}"#.utf8))
        )
        let c = client(transport)
        #expect(try await c.collectAll(Pages()) == [1, 2, 3, 4, 5, 6])

        let transport2 = MockNetworkTransport(default: .json(Data(#"{"values":[9,9]}"#.utf8)))
        #expect(try await client(transport2).collectAll(Runaway(), max: 3) == [9, 9, 9])
        #expect(transport2.requestCount <= 3) // stops early (the stream may prefetch one page)
    }

    @Test("a runaway server is capped at maxPages")
    func runawayCapped() async throws {
        let transport = MockNetworkTransport(default: .json(Data(#"{"values":[1]}"#.utf8)))
        var count = 0
        for try await _ in client(transport).paginate(Runaway(), maxPages: 5) {
            count += 1
        }
        #expect(count == 5)
        #expect(transport.requestCount == 5)
    }

    @Test("cancellation stops the stream mid-way")
    func cancellation() async throws {
        let transport = MockNetworkTransport(default: .json(Data(#"{"values":[1]}"#.utf8)), latency: .milliseconds(30))
        let received = Box()

        let task = Task {
            for try await page in client(transport).paginate(Runaway()) {
                await received.add(page.count)
            }
        }
        try await Task.sleep(for: .milliseconds(120))
        task.cancel()
        _ = await task.result

        // The point: cancellation halted the stream well short of the 1000-page cap.
        #expect(await received.count < 50)
    }
}

private actor Box {
    private(set) var count = 0
    func add(_ n: Int) { count += 1 }
}
