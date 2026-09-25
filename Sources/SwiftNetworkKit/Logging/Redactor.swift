import Foundation

/// Pure, testable redaction of sensitive header values and JSON body keys. The single place that
/// decides what a log line may not contain.
public struct Redactor: Sendable {

    /// Lower-cased header names whose value is always replaced, on top of ``NetworkConfiguration``'s.
    public static let alwaysRedactedHeaders: Set<String> = [
        "authorization", "proxy-authorization", "cookie", "set-cookie",
    ]

    /// Lower-cased URL query item names whose value is always replaced, on top of the configured ones.
    public static let alwaysRedactedQueryItems: Set<String> = [
        "access_token", "refresh_token", "id_token", "token", "api_key", "apikey", "key",
        "password", "secret", "client_secret", "signature", "sig", "code",
    ]

    public static let placeholder = "***"

    private let headerDenylist: Set<String>
    private let bodyKeyDenylist: Set<String>
    private let queryItemDenylist: Set<String>

    /// - Parameters:
    ///   - redactedHeaders: additional header names (any case) to redact.
    ///   - redactedBodyKeys: JSON body keys (exact, case-sensitive) to redact.
    ///   - redactedQueryItems: additional URL query item names (any case) to redact.
    public init(
        redactedHeaders: Set<String> = [],
        redactedBodyKeys: Set<String> = [],
        redactedQueryItems: Set<String> = []
    ) {
        self.headerDenylist = Self.alwaysRedactedHeaders.union(redactedHeaders.map { $0.lowercased() })
        self.bodyKeyDenylist = redactedBodyKeys
        self.queryItemDenylist = Self.alwaysRedactedQueryItems.union(redactedQueryItems.map { $0.lowercased() })
    }

    /// The URL as a printable string with denylisted query item values and any userinfo password
    /// replaced by `***`. Credentials commonly ride in the query (`?access_token=`, signed URLs, an
    /// API key sent with ``APIKeyAuth``), so a URL is never logged verbatim.
    public func redact(url: URL) -> String {
        guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
            return "<unparseable url>"
        }
        if components.password != nil { components.password = Self.placeholder }
        if let items = components.queryItems {
            components.queryItems = items.map { item in
                queryItemDenylist.contains(item.name.lowercased())
                    ? URLQueryItem(name: item.name, value: Self.placeholder)
                    : item
            }
        }
        return components.string ?? "\(url.scheme ?? "")://\(url.host ?? "")\(url.path)"
    }

    /// Returns a copy of `headers` with every denylisted field's value replaced by `***`.
    public func redact(headers: HTTPHeaders) -> HTTPHeaders {
        var out = HTTPHeaders()
        for element in headers {
            out[element.name] =
                headerDenylist.contains(element.name.lowercased())
                ? Self.placeholder
                : element.value
        }
        return out
    }

    /// Returns a printable body string with denylisted JSON keys' values replaced. Non-JSON or
    /// unparseable bodies come back as a byte-count summary so nothing sensitive leaks verbatim.
    public func redact(body data: Data) -> String {
        guard !data.isEmpty else { return "<empty>" }
        guard
            let object = try? JSONSerialization.jsonObject(with: data),
            let redacted = redactJSON(object),
            let out = try? JSONSerialization.data(withJSONObject: redacted, options: [.sortedKeys]),
            let string = String(data: out, encoding: .utf8)
        else {
            return "<\(data.count) bytes>"
        }
        return string
    }

    private func redactJSON(_ value: Any) -> Any? {
        switch value {
        case let dictionary as [String: Any]:
            var out: [String: Any] = [:]
            for (key, nested) in dictionary {
                out[key] = bodyKeyDenylist.contains(key) ? Self.placeholder : (redactJSON(nested) ?? nested)
            }
            return out
        case let array as [Any]:
            return array.map { redactJSON($0) ?? $0 }
        default:
            return value
        }
    }
}
