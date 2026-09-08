/// Content that belongs to a single user.
protocol UserContentRepository: Sendable {
    func fetchPosts(userID: Int) async throws -> [Post]
    func fetchTodos(userID: Int) async throws -> [Todo]
    func fetchAlbums(userID: Int) async throws -> [Album]
}
