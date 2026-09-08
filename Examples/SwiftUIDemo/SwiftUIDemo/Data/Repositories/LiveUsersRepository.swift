import Foundation
import SwiftNetworkKit

struct LiveUsersRepository: UsersRepository {
    let client: NetworkClient

    var pageSize: Int { ListUsersEndpoint.pageSize }

    func fetchUsers(page: Int) async throws -> [User] {
        try await client.request(ListUsersEndpoint(page: page))
    }
}
