import Foundation
import Observation

@MainActor
@Observable
final class UserDetailViewModel {
    let user: User
    private let repository: any UserContentRepository

    private(set) var posts: LoadPhase<[Post]> = .idle
    private(set) var todos: LoadPhase<[Todo]> = .idle
    private(set) var albums: LoadPhase<[Album]> = .idle

    init(user: User, repository: any UserContentRepository) {
        self.user = user
        self.repository = repository
    }

    /// Loads the three collections concurrently.
    func load() async {
        async let p: Void = loadPosts()
        async let t: Void = loadTodos()
        async let a: Void = loadAlbums()
        _ = await (p, t, a)
    }

    private func loadPosts() async {
        posts = .loading
        posts = await .run(previousValue: posts.value) { try await repository.fetchPosts(userID: user.id) }
    }

    private func loadTodos() async {
        todos = .loading
        todos = await .run(previousValue: todos.value) { try await repository.fetchTodos(userID: user.id) }
    }

    private func loadAlbums() async {
        albums = .loading
        albums = await .run(previousValue: albums.value) { try await repository.fetchAlbums(userID: user.id) }
    }
}
