import Foundation
import SwiftNetworkKit

/// One page of `/users`. jsonplaceholder honors `_page` / `_limit`. Conforms to `PaginatedEndpoint`
/// so `client.paginate` / `collectAll` work; the list screen drives it a page at a time.
struct ListUsersEndpoint: PaginatedEndpoint {
    typealias Response = [User]

    var page = 1
    static let pageSize = 4

    var path: String { "/users" }
    var queryParameters: QueryParameters? {
        ["_page": .int(page), "_limit": .int(Self.pageSize)]
    }

    func items(from response: [User]) -> [User] { response }

    func nextPage(after response: [User]) -> ListUsersEndpoint? {
        response.count < Self.pageSize ? nil : ListUsersEndpoint(page: page + 1)
    }
}
