import Foundation

/// Applies authentication to an outgoing request.
///
/// The `token` argument is the current access token from the client's ``TokenStorage`` (via
/// ``TokenManager``), or `nil` when none is available — strategies that don't use a bearer token
/// (API key, basic) simply ignore it.
public protocol AuthStrategy: Sendable {
    func authorize(_ request: inout URLRequest, token: String?) async throws
}

/// `Authorization: Bearer <token>`. No-op when `token` is `nil`.
public struct BearerAuth: AuthStrategy {
    public init() {}

    public func authorize(_ request: inout URLRequest, token: String?) async throws {
        guard let token else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}

/// A static API key, sent either as a header or as a query item.
public struct APIKeyAuth: AuthStrategy {
    public enum Placement: Sendable {
        case header(name: String)
        case query(name: String)
    }

    public let placement: Placement
    public let value: String

    public init(header name: String, value: String) {
        self.placement = .header(name: name)
        self.value = value
    }

    public init(query name: String, value: String) {
        self.placement = .query(name: name)
        self.value = value
    }

    public func authorize(_ request: inout URLRequest, token: String?) async throws {
        switch placement {
        case .header(let name):
            request.setValue(value, forHTTPHeaderField: name)
        case .query(let name):
            guard let url = request.url,
                  var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return }
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: name, value: value))
            components.queryItems = items
            request.url = components.url
        }
    }
}

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

/// An arbitrary app-supplied authentication closure.
public struct CustomAuth: AuthStrategy {
    private let apply: @Sendable (_ request: inout URLRequest, _ token: String?) async throws -> Void

    public init(_ apply: @escaping @Sendable (_ request: inout URLRequest, _ token: String?) async throws -> Void) {
        self.apply = apply
    }

    public func authorize(_ request: inout URLRequest, token: String?) async throws {
        try await apply(&request, token)
    }
}
