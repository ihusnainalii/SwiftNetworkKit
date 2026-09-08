import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("Batch & zip")
struct BatchTests {

    private struct Value: Codable, Equatable, Sendable { let n: Int }
    private struct Get: Endpoint {
        typealias Response = Value
        let path: String
    }

    private func client(_ transport: MockNetworkTransport) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("zip returns both responses")
    func zipTwo() async throws {
        let transport = MockNetworkTransport(default: .json(Data(#"{"n":7}"#.utf8)))
        let (a, b) = try await client(transport).zip(Get(path: "/a"), Get(path: "/b"))
        #expect(a == Value(n: 7))
        #expect(b == Value(n: 7))
        #expect(transport.requestCount == 2)
    }

    @Test("zip of three returns all three")
    func zipThree() async throws {
        let transport = MockNetworkTransport(default: .json(Data(#"{"n":1}"#.utf8)))
        let (a, b, c) = try await client(transport).zip(Get(path: "/a"), Get(path: "/b"), Get(path: "/c"))
        #expect([a, b, c] == [Value(n: 1), Value(n: 1), Value(n: 1)])
    }

    @Test("zip throws if either endpoint fails")
    func zipFailure() async {
        let transport = MockNetworkTransport(default: .json(Data(#"{"n":1}"#.utf8)))
        transport.enqueue(.status(500)) // one of the two requests gets this
        await #expect(throws: NetworkError.self) {
            _ = try await client(transport).zip(Get(path: "/a"), Get(path: "/b"))
        }
    }

    @Test("batch returns one result per input and isolates failures")
    func batchResults() async {
        let transport = MockNetworkTransport(default: .json(Data(#"{"n":1}"#.utf8)))
        transport.enqueue(.status(404)) // exactly one of the three fails
        let results = await client(transport).batch([Get(path: "/a"), Get(path: "/b"), Get(path: "/c")])

        #expect(results.count == 3)
        #expect(results.compactMap { try? $0.get() }.count == 2)
        let failures = results.compactMap { result -> NetworkError? in
            if case .failure(let error) = result { return error }
            return nil
        }
        #expect(failures.map(\.code) == [.notFound])
    }

    @Test("batch of an empty array is an empty array")
    func batchEmpty() async {
        let results = await client(MockNetworkTransport()).batch([Get]())
        #expect(results.isEmpty)
    }
}
