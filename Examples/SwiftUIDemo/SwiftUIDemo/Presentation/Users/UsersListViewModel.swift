import Foundation
import Observation

@MainActor
@Observable
final class UsersListViewModel {
    private let repository: any UsersRepository

    /// The accumulated list, page by page.
    private(set) var phase: LoadPhase<[User]> = .idle
    private(set) var isLoadingMore = false
    private(set) var canLoadMore = false
    var search = ""

    private var loadedPages = 0

    init(repository: any UsersRepository) {
        self.repository = repository
    }

    var visibleUsers: [User] {
        guard let all = phase.value else { return [] }
        guard !search.isEmpty else { return all }
        let needle = search.lowercased()
        return all.filter {
            $0.name.lowercased().contains(needle)
                || $0.username.lowercased().contains(needle)
                || $0.company.name.lowercased().contains(needle)
        }
    }

    func loadIfNeeded() async {
        guard phase.value == nil else { return }
        await load()
    }

    /// Fresh load: page 1.
    func load() async {
        if phase.value == nil { phase = .loading }
        loadedPages = 0
        phase = await .run(previousValue: phase.value) {
            let first = try await repository.fetchUsers(page: 1)
            return first
        }
        if case .loaded(let users) = phase {
            loadedPages = 1
            canLoadMore = users.count == repository.pageSize
        }
    }

    /// Appends the next page. Called when the list scrolls near the end.
    func loadMore() async {
        guard canLoadMore, !isLoadingMore, case .loaded(let current) = phase, search.isEmpty else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        do {
            let next = try await repository.fetchUsers(page: loadedPages + 1)
            loadedPages += 1
            phase = .loaded(current + next)
            canLoadMore = next.count == repository.pageSize
        } catch {
            canLoadMore = false // stop trying; the visible list stays intact
        }
    }
}
