import Foundation
import SwiftNetworkKit

struct LiveUsersRepository: UsersRepository {
    let client: NetworkClient

    func fetchUsers() async throws -> [User] {
        try await client.request(ListUsersEndpoint())
    }
}
