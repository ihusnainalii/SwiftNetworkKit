import Foundation
import SwiftNetworkKit

struct LivePostComposer: PostComposer {
    let client: NetworkClient

    func createPost(_ draft: DraftPost) async throws -> Post {
        try await client.request(CreatePostEndpoint(draft: draft))
    }
}
