import SwiftUI

struct ComposePostView: View {
    @State private var model: ComposePostViewModel

    init(container: AppContainer) {
        _model = State(wrappedValue: ComposePostViewModel(composer: container.composer))
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("New post") {
                    TextField("Title", text: $model.title)
                    TextField("Body", text: $model.body, axis: .vertical).lineLimit(3...6)
                    Stepper("Author user ID: \(model.authorID)", value: $model.authorID, in: 1...10)
                }

                Section {
                    Button {
                        Task { await model.submit() }
                    } label: {
                        if model.result.isLoading {
                            HStack { ProgressView(); Text("Posting…") }
                        } else {
                            Text("POST /posts")
                        }
                    }
                    .disabled(!model.canSubmit)
                }

                switch model.result {
                case .loaded(let post):
                    Section("Server response") {
                        LabeledContent("New id", value: "\(post.id)")
                        LabeledContent("Title", value: post.title)
                        Text("Sent as a JSON body; decoded straight into `Post`.")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                case .failed(let error):
                    Section {
                        Label(error.localizedDescription, systemImage: "xmark.octagon")
                            .foregroundStyle(.red)
                    }
                case .idle, .loading:
                    EmptyView()
                }
            }
            .navigationTitle("Compose")
        }
    }
}
