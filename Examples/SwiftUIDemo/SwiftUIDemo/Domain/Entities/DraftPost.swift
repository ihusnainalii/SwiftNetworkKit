import Foundation

struct DraftPost: Codable, Sendable {
    let title: String
    let body: String
    let userID: Int

    enum CodingKeys: String, CodingKey {
        case title, body
        case userID = "userId"
    }
}
