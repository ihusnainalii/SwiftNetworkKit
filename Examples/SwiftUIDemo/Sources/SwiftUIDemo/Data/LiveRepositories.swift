import Foundation
import SwiftNetworkKit

/// Repository implementations backed by a `NetworkClient`. This is the only place `client.request`
/// is called from — view models never see SwiftNetworkKit.

struct LiveUsersRepository: UsersRepository {
    let client: NetworkClient

    func fetchUsers() async throws -> [User] {
        try await client.request(API.ListUsers())
    }
}

struct LiveUserContentRepository: UserContentRepository {
    let client: NetworkClient

    func fetchPosts(userID: Int) async throws -> [Post] {
        try await client.request(API.PostsByUser(userID: userID))
    }

    func fetchTodos(userID: Int) async throws -> [Todo] {
        try await client.request(API.TodosByUser(userID: userID))
    }

    func fetchAlbums(userID: Int) async throws -> [Album] {
        try await client.request(API.AlbumsByUser(userID: userID))
    }
}

struct LivePostComposer: PostComposer {
    let client: NetworkClient

    func createPost(_ draft: DraftPost) async throws -> Post {
        try await client.request(API.CreatePost(draft: draft))
    }
}
