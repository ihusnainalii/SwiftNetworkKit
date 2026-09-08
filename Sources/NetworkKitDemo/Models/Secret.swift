import Foundation

/// Response body for the mock auth-refresh walkthrough.
struct Secret: Codable, Sendable {
    let value: String
}
