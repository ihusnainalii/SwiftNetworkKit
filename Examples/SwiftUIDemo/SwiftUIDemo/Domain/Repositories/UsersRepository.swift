/// The presentation layer's view of "where users come from". Implemented in the Data layer.
protocol UsersRepository: Sendable {
    /// One page of users (1-based). An empty or short page means there are no more.
    func fetchUsers(page: Int) async throws -> [User]

    /// The page size the Data layer uses, so the view model can tell when a page was the last one.
    var pageSize: Int { get }
}
