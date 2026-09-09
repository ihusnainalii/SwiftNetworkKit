import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

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
                var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
            else { return }
            var items = components.queryItems ?? []
            items.append(URLQueryItem(name: name, value: value))
            components.queryItems = items
            request.url = components.url
        }
    }
}
