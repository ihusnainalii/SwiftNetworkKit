/// The presentation layer's view of "where users come from". Implemented in the Data layer.
protocol UsersRepository: Sendable {
    func fetchUsers() async throws -> [User]
}
