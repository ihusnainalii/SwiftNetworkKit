#if canImport(Combine)
import Foundation
import Combine
import Testing
@testable import SwiftNetworkKit

@Suite("Combine publishers")
struct PublisherTests {

    private struct Thing: Codable, Equatable, Sendable { let v: Int }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
    }

    private func client(_ transport: MockNetworkTransport) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        return NetworkClient(configuration: config, transport: transport)
    }

    /// Drains a publisher to (values, completion).
    private func drain<P: Publisher>(_ publisher: P) async -> ([P.Output], Subscribers.Completion<P.Failure>) {
        await withCheckedContinuation { continuation in
            let box = Collected<P.Output, P.Failure>()
            box.cancellable = publisher.sink(
                receiveCompletion: { completion in
                    continuation.resume(returning: (box.values, completion))
                },
                receiveValue: { box.values.append($0) }
            )
        }
    }

    @Test("publisher(for:) emits one value then finishes")
    func oneShotSuccess() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"v":42}"#.utf8)))
        let (values, completion) = await drain(client(transport).publisher(for: GetThing()))
        #expect(values == [Thing(v: 42)])
        if case .finished = completion {} else { Issue.record("expected .finished") }
    }

    @Test("the error path completes with .failure(NetworkError)")
    func errorPath() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(500))
        let (values, completion) = await drain(client(transport).publisher(for: GetThing()))
        #expect(values.isEmpty)
        guard case .failure(let error) = completion else { Issue.record("expected .failure"); return }
        #expect(error.code == .server)
    }

    @Test("cancelling the subscription cancels the request")
    func cancellation() async {
        let transport = MockNetworkTransport(latency: .milliseconds(300))
        transport.enqueue(.json(Data(#"{"v":1}"#.utf8)))
        let completed = Flag()

        let cancellable = client(transport).publisher(for: GetThing())
            .sink(receiveCompletion: { _ in completed.set() }, receiveValue: { _ in completed.set() })
        try? await Task.sleep(for: .milliseconds(30))
        cancellable.cancel()
        try? await Task.sleep(for: .milliseconds(50))
        #expect(completed.value == false) // no completion delivered — the task was torn down
    }

    @Test("paginatePublisher emits one value per page then finishes")
    func pagination() async {
        struct Chunk: Codable, Sendable { let values: [Int] }
        struct Pages: PaginatedEndpoint {
            typealias Response = Chunk
            var page = 1
            var path: String { "/n" }
            var queryParameters: QueryParameters? { ["p": .int(page)] }
            func items(from response: Chunk) -> [Int] { response.values }
            func nextPage(after response: Chunk) -> Pages? { response.values.isEmpty ? nil : Pages(page: page + 1) }
        }
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"{"values":[1,2]}"#.utf8)),
            .json(Data(#"{"values":[3]}"#.utf8)),
            .json(Data(#"{"values":[]}"#.utf8))
        )
        let (pages, completion) = await drain(client(transport).paginatePublisher(Pages()))
        #expect(pages == [[1, 2], [3], []])
        if case .finished = completion {} else { Issue.record("expected .finished") }
    }
}

private final class Collected<Value, Failure: Error>: @unchecked Sendable {
    var values: [Value] = []
    var cancellable: AnyCancellable?
}

private final class Flag: @unchecked Sendable {
    private let lock = NSLock()
    private var flag = false
    func set() { lock.withLock { flag = true } }
    var value: Bool { lock.withLock { flag } }
}
#endif
