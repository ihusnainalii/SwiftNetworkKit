#if canImport(Observation)
import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("NetworkResource & Paged")
struct NetworkResourceTests {

    private typealias Availability = Void // marker; each @Test carries the @available below

    private struct Thing: Codable, Equatable, Sendable { let v: Int }
    private struct GetThing: Endpoint {
        typealias Response = [Thing]
        let path = "/things"
    }

    private struct Row: Codable, Equatable, Sendable, Identifiable { let id: Int }
    private struct RowsPage: PaginatedEndpoint {
        typealias Response = [Row]
        var page = 1
        var path: String { "/rows" }
        var queryParameters: QueryParameters? { ["p": .int(page)] }
        func items(from response: [Row]) -> [Row] { response }
        func nextPage(after response: [Row]) -> RowsPage? { response.isEmpty ? nil : RowsPage(page: page + 1) }
    }

    @MainActor
    private func client(_ transport: MockNetworkTransport) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("load transitions idle -> loading -> loaded and exposes value")
    @MainActor
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
    func loadSuccess() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"[{"v":1},{"v":2}]"#.utf8)))
        let resource = NetworkResource<[Thing]>(client: client(transport))

        #expect(resource.isLoading == false)
        await resource.load(GetThing())
        #expect(resource.value == [Thing(v: 1), Thing(v: 2)])
        #expect(resource.error == nil)
    }

    @Test("a failure surfaces as .failed with a NetworkError")
    @MainActor
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
    func loadFailure() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(404))
        let resource = NetworkResource<[Thing]>(client: client(transport))
        await resource.load(GetThing())
        #expect(resource.value == nil)
        #expect(resource.error?.code == .notFound)
    }

    @Test("reload re-runs the last load")
    @MainActor
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
    func reload() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"[{"v":1}]"#.utf8)), .json(Data(#"[{"v":1},{"v":2}]"#.utf8)))
        let resource = NetworkResource<[Thing]>(client: client(transport))
        await resource.load(GetThing())
        #expect(resource.value?.count == 1)
        await resource.reload()
        #expect(resource.value?.count == 2)
    }

    @Test("Paged.start loads the first page; loadMoreIfNeeded appends the next")
    @MainActor
    @available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
    func paged() async {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"[{"id":1},{"id":2}]"#.utf8)),
            .json(Data(#"[{"id":3},{"id":4}]"#.utf8)),
            .json(Data(#"[]"#.utf8))
        )
        let paged = Paged<Row>(client: client(transport))
        await paged.start(RowsPage())
        #expect(paged.items == [Row(id: 1), Row(id: 2)])
        #expect(paged.canLoadMore)

        await paged.loadMoreIfNeeded(currentItem: Row(id: 2))
        #expect(paged.items.map(\.id) == [1, 2, 3, 4])

        await paged.loadMoreIfNeeded(currentItem: Row(id: 4))
        #expect(paged.canLoadMore == false) // empty page ended it
    }
}
#endif
