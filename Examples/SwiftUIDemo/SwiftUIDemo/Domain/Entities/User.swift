import Foundation

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
