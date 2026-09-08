import Foundation
import SwiftNetworkKit

// MARK: - Models

struct User: Codable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
}

struct Post: Codable, Sendable {
    let id: Int
    let userID: Int
    let title: String
    let body: String

    // JSONPlaceholder uses `userId`; the default decoder converts snake_case, not camelCase quirks,
    // so map it explicitly.
    enum CodingKeys: String, CodingKey {
        case id, title, body
        case userID = "userId"
    }
}

struct DraftPost: Codable, Sendable {
    let title: String
    let body: String
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case title, body
        case userID = "userId"
    }
}

// MARK: - Endpoints
//
// This is the *entire* integration surface an app writes: one type per operation. No URLSession,
// no decoding boilerplate, no error mapping.

enum JSONPlaceholder {

    struct GetUser: Endpoint {
        typealias Response = User
        let id: Int
        var path: String { "/users/:id" }
        var pathParameters: [String: String] { ["id": String(id)] }
    }

    struct ListPosts: Endpoint {
        typealias Response = [Post]
        var authorUserID: Int?
        var path: String { "/posts" }
        var queryParameters: QueryParameters? {
            guard let authorUserID else { return nil }
            return ["userId": .int(authorUserID)]
        }
    }

    struct CreatePost: Endpoint {
        typealias Response = Post
        let draft: DraftPost
        var path: String { "/posts" }
        var method: HTTPMethod { .post }
        var body: RequestBody? { .json(draft) }
    }

    /// Always 404s — used to demo error handling.
    struct MissingUser: Endpoint {
        typealias Response = User
        var path: String { "/users/999999" }
    }
}
