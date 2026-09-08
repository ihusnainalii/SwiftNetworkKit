import Foundation
import SwiftNetworkKit

struct LiveUserContentRepository: UserContentRepository {
    let client: NetworkClient

    func fetchPosts(userID: Int) async throws -> [Post] {
        try await client.request(PostsByUserEndpoint(userID: userID))
    }

    func fetchTodos(userID: Int) async throws -> [Todo] {
        try await client.request(TodosByUserEndpoint(userID: userID))
    }

    func fetchAlbums(userID: Int) async throws -> [Album] {
        try await client.request(AlbumsByUserEndpoint(userID: userID))
    }
}
