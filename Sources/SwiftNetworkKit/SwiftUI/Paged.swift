#if canImport(Observation)
import Foundation
import Observation

/// An observable, append-as-you-scroll list driven by a ``PaginatedEndpoint``.
///
/// ```swift
/// @State private var feed = Paged<Post>(client: .live)
///
/// List {
///     ForEach(feed.items) { post in
///         PostRow(post: post).onAppear { Task { await feed.loadMoreIfNeeded(currentItem: post) } }
///     }
///     if feed.isLoadingMore { ProgressView() }
/// }
/// .task { await feed.start(FeedPage()) }
/// ```
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
@MainActor
@Observable
public final class Paged<Item: Sendable & Identifiable> {

    public private(set) var items: [Item] = []
    public private(set) var isLoadingMore = false
    public private(set) var canLoadMore = true
    public private(set) var error: NetworkError?

    private let client: NetworkClient
    private var advance: (@Sendable () async -> PagedResult<Item>)?

    public init(client: NetworkClient) {
        self.client = client
    }

    /// Begins pagination: loads the first page and prepares to fetch more.
    public func start<E: PaginatedEndpoint>(_ endpoint: E) async where E.Item == Item {
        items = []
        error = nil
        canLoadMore = true
        let cursor = PageCursor(endpoint, client: client)
        advance = { await cursor.next() }
        await fetchNextPage()
    }

    /// Fetches the next page when `currentItem` is within 3 rows of the end of the loaded list.
    public func loadMoreIfNeeded(currentItem: Item?) async {
        guard canLoadMore, !isLoadingMore,
            let currentItem,
            let position = items.firstIndex(where: { $0.id == currentItem.id }),
            position >= items.count - 3
        else { return }
        await fetchNextPage()
    }

    private func fetchNextPage() async {
        guard let advance, canLoadMore, !isLoadingMore else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        switch await advance() {
        case .page(let page):
            items.append(contentsOf: page)
            if page.isEmpty { canLoadMore = false }
        case .finished:
            canLoadMore = false
        case .failure(let error):
            self.error = error
            canLoadMore = false
        }
    }
}

/// The outcome of pulling one page.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
enum PagedResult<Item: Sendable>: Sendable {
    case page([Item])
    case finished
    case failure(NetworkError)
}

/// Drives a ``PaginatedEndpoint`` one page at a time, holding the "next" endpoint between calls.
@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)
private actor PageCursor<E: PaginatedEndpoint> {
    private var current: E?
    private let client: NetworkClient

    init(_ endpoint: E, client: NetworkClient) {
        self.current = endpoint
        self.client = client
    }

    func next() async -> PagedResult<E.Item> {
        guard let page = current else { return .finished }
        do {
            let response = try await client.request(page)
            current = page.nextPage(after: response)
            return .page(page.items(from: response))
        } catch is CancellationError {
            return .finished
        } catch {
            return .failure(NetworkError.normalize(error))
        }
    }
}
#endif
