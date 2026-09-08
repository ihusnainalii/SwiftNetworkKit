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
