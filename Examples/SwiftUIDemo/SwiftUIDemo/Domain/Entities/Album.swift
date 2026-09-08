import Foundation

struct Album: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
}
