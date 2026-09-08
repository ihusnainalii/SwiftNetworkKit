import Foundation
import SwiftNetworkKit

struct CreatePostEndpoint: Endpoint {
    typealias Response = Post
    let draft: DraftPost
    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var body: RequestBody? { .json(draft) }
}
