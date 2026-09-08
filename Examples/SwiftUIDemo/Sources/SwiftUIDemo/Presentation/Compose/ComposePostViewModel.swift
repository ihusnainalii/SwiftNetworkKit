import Foundation
import Observation

@MainActor
@Observable
final class ComposePostViewModel {
    private let composer: any PostComposer

    var title = ""
    var body = ""
    var authorID = 1
    private(set) var result: LoadPhase<Post> = .idle

    init(composer: any PostComposer) {
        self.composer = composer
    }

    var canSubmit: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
            && !body.trimmingCharacters(in: .whitespaces).isEmpty
            && !result.isLoading
    }

    func submit() async {
        let draft = DraftPost(title: title, body: body, userID: authorID)
        result = .loading
        result = await .run(previousValue: nil) { try await composer.createPost(draft) }
    }
}
