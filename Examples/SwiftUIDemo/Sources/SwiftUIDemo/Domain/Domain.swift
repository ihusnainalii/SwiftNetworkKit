import Foundation

// MARK: - Entities
//
// Plain value types the presentation layer works with. (For a demo they double as the wire DTOs;
// a larger app would keep Codable DTOs in Data/ and map to these.)

struct User: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let name: String
    let username: String
    let email: String
    let phone: String
    let website: String
    let address: Address
    let company: Company

    struct Address: Codable, Hashable, Sendable {
        let street: String
        let suite: String
        let city: String
        let zipcode: String
    }

    struct Company: Codable, Hashable, Sendable {
        let name: String
        let catchPhrase: String
    }
}

struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let body: String
}

struct Todo: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let completed: Bool
}

struct Album: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
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

// MARK: - Repository ports
//
// The presentation layer depends only on these protocols — never on SwiftNetworkKit directly.

protocol UsersRepository: Sendable {
    func fetchUsers() async throws -> [User]
}

protocol UserContentRepository: Sendable {
    func fetchPosts(userID: Int) async throws -> [Post]
    func fetchTodos(userID: Int) async throws -> [Todo]
    func fetchAlbums(userID: Int) async throws -> [Album]
}

protocol PostComposer: Sendable {
    func createPost(_ draft: DraftPost) async throws -> Post
}

/// A step in a scripted diagnostic scenario.
struct DiagnosticEvent: Sendable, Identifiable {
    enum Kind: Sendable { case info, success, warning, failure }
    let id = UUID()
    let message: String
    let kind: Kind
}

/// Drives the "how does automatic 401 refresh work" walkthrough on the Diagnostics screen.
protocol NetworkDiagnostics: Sendable {
    var baseURL: String { get }
    var defaultHeaders: [String: String] { get }
    /// Emits one event per step of a mock 401 → refresh → retry flow.
    func runAuthRefreshScenario() -> AsyncStream<DiagnosticEvent>
}
