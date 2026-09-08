import Foundation
import Observation

@MainActor
@Observable
final class UsersListViewModel {
    private let repository: any UsersRepository

    private(set) var phase: LoadPhase<[User]> = .idle
    var search = ""

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

    func load() async {
        if phase.value == nil { phase = .loading }
        phase = await .run(previousValue: phase.value) {
            try await repository.fetchUsers()
        }
    }
}
