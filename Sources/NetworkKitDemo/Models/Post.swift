import Foundation

struct Post: Codable, Sendable {
    let id: Int
    let userID: Int
    let title: String
    let body: String

    enum CodingKeys: String, CodingKey {
        case id, title, body
        case userID = "userId"
    }
}
