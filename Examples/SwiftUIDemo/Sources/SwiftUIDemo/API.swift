import Foundation
import SwiftNetworkKit

// MARK: - Models

struct User: Codable, Identifiable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String
    let website: String
}

struct Post: Codable, Identifiable, Sendable {
    let id: Int
    let title: String
    let body: String
}

// MARK: - Endpoints
//
// The whole integration surface: one type per API operation. No URLSession, no decoding code.

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
}

// MARK: - Client

extension NetworkClient {
    /// One shared, pre-configured client for the whole app.
    static let jsonPlaceholder = NetworkClient(
        configuration: NetworkConfiguration(
            baseURL: "https://jsonplaceholder.typicode.com",
            headers: ["Accept": "application/json"]
        )
    )
}
