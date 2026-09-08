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
                List {
                    ForEach(model.visibleUsers) { user in
                        NavigationLink(value: user) { UserRow(user: user) }
                    }
                    if model.canLoadMore && model.search.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .listRowSeparator(.hidden)
                        .task { await model.loadMore() }
                    }
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
