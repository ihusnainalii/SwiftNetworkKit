import Foundation
import SwiftNetworkKit

/// SwiftNetworkKit endpoint definitions — the Data layer's only knowledge of the remote API shape.

enum API {
    struct ListUsers: Endpoint {
        typealias Response = [User]
        var path: String { "/users" }
    }

    struct PostsByUser: Endpoint {
        typealias Response = [Post]
        let userID: Int
        var path: String { "/posts" }
        var queryParameters: QueryParameters? { ["userId": .int(userID)] }
    }

    struct TodosByUser: Endpoint {
        typealias Response = [Todo]
        let userID: Int
        var path: String { "/todos" }
        var queryParameters: QueryParameters? { ["userId": .int(userID)] }
    }

    struct AlbumsByUser: Endpoint {
        typealias Response = [Album]
        let userID: Int
        var path: String { "/albums" }
        var queryParameters: QueryParameters? { ["userId": .int(userID)] }
    }

    struct CreatePost: Endpoint {
        typealias Response = Post
        let draft: DraftPost
        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var body: RequestBody? { .json(draft) }
    }
}
