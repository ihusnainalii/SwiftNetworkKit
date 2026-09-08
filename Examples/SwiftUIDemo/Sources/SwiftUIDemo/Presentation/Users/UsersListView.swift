import SwiftUI

struct UsersListView: View {
    private let container: AppContainer
    @State private var model: UsersListViewModel

    init(container: AppContainer) {
        self.container = container
        _model = State(wrappedValue: UsersListViewModel(repository: container.users))
    }

    var body: some View {
        NavigationStack {
            PhaseView(phase: model.phase, retry: { Task { await model.load() } }) { _ in
                List(model.visibleUsers) { user in
                    NavigationLink(value: user) { UserRow(user: user) }
                }
                .refreshable { await model.load() }
                .overlay {
                    if model.visibleUsers.isEmpty {
                        ContentUnavailableView.search(text: model.search)
                    }
                }
            }
            .navigationTitle("Users")
            .searchable(text: $model.search, prompt: "Name, username or company")
            .navigationDestination(for: User.self) { user in
                UserDetailView(user: user, container: container)
            }
        }
        .task { await model.loadIfNeeded() }
    }
}

private struct UserRow: View {
    let user: User

    var body: some View {
        HStack(spacing: 12) {
            Text(initials)
                .font(.headline)
                .frame(width: 40, height: 40)
                .background(.tint.opacity(0.15), in: Circle())
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name).font(.headline)
                Text("@\(user.username) · \(user.company.name)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }

    private var initials: String {
        user.name.split(separator: " ").prefix(2).compactMap(\.first).map(String.init).joined()
    }
}
