import Foundation

/// An ``Endpoint`` that returns one page of a larger collection.
///
/// The endpoint owns the pagination scheme entirely: `nextPage(after:)` builds the request for the
/// following page from the response you just got (a cursor, a `page+1`, a `Link:` header, …) and
/// returns `nil` when there are no more.
///
/// ```swift
/// struct ListUsers: PaginatedEndpoint {
///     typealias Response = Page<User>
///     var page = 1
///     var path: String { "/users" }
///     var queryParameters: QueryParameters? { ["page": .int(page), "per_page": .int(50)] }
///     func items(from response: Page<User>) -> [User] { response.items }
///     func nextPage(after response: Page<User>) -> Self? {
///         response.items.isEmpty ? nil : { var next = self; next.page += 1; return next }()
///     }
/// }
///
/// for try await batchOfUsers in client.paginate(ListUsers()) { ... }
/// ```
public protocol PaginatedEndpoint: Endpoint {
    associatedtype Item: Sendable

    /// The items on this page.
    func items(from response: Response) -> [Item]

    /// The endpoint for the next page, or `nil` if this was the last one.
    func nextPage(after response: Response) -> Self?
}
