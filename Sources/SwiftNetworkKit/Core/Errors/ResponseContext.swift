import Foundation

/// Everything about a server response needed to diagnose a failure.
public struct ResponseContext: Sendable {
    public let statusCode: Int
    public let headers: HTTPHeaders
    public let data: Data?
    public let request: URLRequest

    public init(statusCode: Int, headers: HTTPHeaders, data: Data?, request: URLRequest) {
        self.statusCode = statusCode
        self.headers = headers
        self.data = data
        self.request = request
    }

    /// Best-effort extraction of a human-readable message from a JSON or plain-text error body.
    public var serverMessage: String? {
        guard let data, !data.isEmpty else { return nil }
        if let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
            for key in ["message", "error_description", "error", "detail", "title"] {
                if let string = object[key] as? String, !string.isEmpty { return string }
            }
            if let errors = object["errors"] as? [[String: Any]],
                let first = errors.lazy.compactMap({ $0["message"] as? String }).first
            {
                return first
            }
            if let errors = object["errors"] as? [String], let first = errors.first { return first }
        }
        if let string = String(data: data, encoding: .utf8), (1...500).contains(string.count) {
            return string
        }
        return nil
    }
}
