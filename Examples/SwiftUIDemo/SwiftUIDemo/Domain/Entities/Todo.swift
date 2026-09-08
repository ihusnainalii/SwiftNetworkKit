import Foundation

struct Todo: Codable, Identifiable, Hashable, Sendable {
    let id: Int
    let title: String
    let completed: Bool
}
