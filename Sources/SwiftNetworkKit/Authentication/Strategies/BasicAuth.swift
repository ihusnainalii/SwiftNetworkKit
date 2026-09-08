import Foundation

/// HTTP Basic authentication: `Authorization: Basic base64(username:password)`.
public struct BasicAuth: AuthStrategy {
    public let username: String
    public let password: String

    public init(username: String, password: String) {
        self.username = username
        self.password = password
    }

    public func authorize(_ request: inout URLRequest, token: String?) async throws {
        let encoded = Data("\(username):\(password)".utf8).base64EncodedString()
        request.setValue("Basic \(encoded)", forHTTPHeaderField: "Authorization")
    }
}
