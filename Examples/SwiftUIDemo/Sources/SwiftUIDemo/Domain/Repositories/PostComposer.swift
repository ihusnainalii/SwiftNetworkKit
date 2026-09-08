/// Creates new posts.
protocol PostComposer: Sendable {
    func createPost(_ draft: DraftPost) async throws -> Post
}
