import SwiftUI

struct UserDetailView: View {
    @State private var model: UserDetailViewModel

    init(user: User, container: AppContainer) {
        _model = State(wrappedValue: UserDetailViewModel(user: user, repository: container.userContent))
    }

    var body: some View {
        List {
            Section("Contact") {
                LabeledContent("Email", value: model.user.email)
                LabeledContent("Phone", value: model.user.phone)
                LabeledContent("Website", value: model.user.website)
                LabeledContent("City", value: model.user.address.city)
                LabeledContent("Company", value: model.user.company.name)
            }

            CountedSection("Posts", phase: model.posts) { list in
                ForEach(list) { post in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(post.title).font(.headline)
                        Text(post.body).font(.subheadline).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 2)
                }
            }

            CountedSection("Todos", phase: model.todos) { list in
                ForEach(list) { todo in
                    Label(todo.title, systemImage: todo.completed ? "checkmark.circle.fill" : "circle")
                        .foregroundStyle(todo.completed ? .secondary : .primary)
                }
            }

            CountedSection("Albums", phase: model.albums) { list in
                ForEach(list) { album in Text(album.title) }
            }
        }
        .navigationTitle(model.user.name)
        .task { await model.load() }
    }
}

/// A section whose header shows a count once loaded; a spinner while loading; the error inline.
private struct CountedSection<Element: Sendable, Rows: View>: View {
    let title: String
    let phase: LoadPhase<[Element]>
    @ViewBuilder let rows: ([Element]) -> Rows

    init(_ title: String, phase: LoadPhase<[Element]>, @ViewBuilder rows: @escaping ([Element]) -> Rows) {
        self.title = title
        self.phase = phase
        self.rows = rows
    }

    var body: some View {
        Section {
            switch phase {
            case .idle, .loading:
                ProgressView()
            case .loaded(let list):
                rows(list)
            case .failed(let error):
                Text(error.localizedDescription).font(.callout).foregroundStyle(.red)
            }
        } header: {
            HStack {
                Text(title)
                if case .loaded(let list) = phase {
                    Text("\(list.count)").foregroundStyle(.secondary)
                }
            }
        }
    }
}
