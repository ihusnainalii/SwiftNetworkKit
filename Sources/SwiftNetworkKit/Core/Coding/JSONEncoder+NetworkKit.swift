import Foundation

public extension JSONEncoder {
    /// SwiftNetworkKit's default encoder: `convertToSnakeCase` keys, ISO-8601 dates.
    static var networkKitDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
