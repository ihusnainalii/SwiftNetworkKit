import Foundation

struct Post: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let body: String
}
