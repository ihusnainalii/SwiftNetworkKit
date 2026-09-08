import Foundation

public extension JSONDecoder {
    /// SwiftNetworkKit's default decoder: `convertFromSnakeCase` keys, ISO-8601 dates.
    static var networkKitDefault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}

public extension JSONEncoder {
    /// SwiftNetworkKit's default encoder: `convertToSnakeCase` keys, ISO-8601 dates.
    static var networkKitDefault: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        encoder.dateEncodingStrategy = .iso8601
        return encoder
    }
}
