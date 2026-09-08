import SwiftUI
import SwiftNetworkKit

struct ContentView: View {
    @State private var users = Loadable<[User]>()

    var body: some View {
        NavigationStack {
            content
                .navigationTitle("Users")
                .navigationDestination(for: User.self) { user in
                    UserDetailView(user: user)
                }
        }
        .task {
            if users.value == nil { await reload() }
        }
    }

    @ViewBuilder
    private var content: some View {
        switch users.phase {
        case .idle, .loading:
            ProgressView("Loading users…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)

        case .loaded(let list):
            List(list) { user in
                NavigationLink(value: user) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.name).font(.headline)
                        Text(user.email).font(.caption).foregroundStyle(.secondary)
                    }
                }
            }
            .refreshable { await reload() }

        case .failed(let error):
            ContentUnavailableView {
                Label("Couldn’t load users", systemImage: "wifi.slash")
            } description: {
                Text(error.localizedDescription)
            } actions: {
                Button("Retry") { Task { await reload() } }
            }
        }
    }

    private func reload() async {
        await users.load {
            try await NetworkClient.jsonPlaceholder.request(API.ListUsers())
        }
    }
}

struct UserDetailView: View {
    let user: User
    @State private var posts = Loadable<[Post]>()

    var body: some View {
        List {
            Section("Contact") {
                LabeledContent("Username", value: "@\(user.username)")
                LabeledContent("Email", value: user.email)
                LabeledContent("Phone", value: user.phone)
                LabeledContent("Website", value: user.website)
            }

            Section("Posts") {
                switch posts.phase {
                case .idle, .loading:
                    ProgressView()
                case .loaded(let list):
                    ForEach(list) { post in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(post.title).font(.headline)
                            Text(post.body).font(.subheadline).foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 2)
                    }
                case .failed(let error):
                    Text(error.localizedDescription).foregroundStyle(.red)
                }
            }
        }
        .navigationTitle(user.name)
        .task {
            await posts.load {
                try await NetworkClient.jsonPlaceholder.request(API.PostsByUser(userID: user.id))
            }
        }
    }
}

extension User: Hashable {
    static func == (lhs: User, rhs: User) -> Bool { lhs.id == rhs.id }
    func hash(into hasher: inout Hasher) { hasher.combine(id) }
}
