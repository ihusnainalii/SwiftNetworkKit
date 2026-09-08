import Foundation

extension JSONDecoder {
    /// SwiftNetworkKit's default decoder: `convertFromSnakeCase` keys, ISO-8601 dates.
    public static var networkKitDefault: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
