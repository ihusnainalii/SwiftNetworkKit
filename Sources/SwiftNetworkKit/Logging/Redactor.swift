import Foundation

/// Pure, testable redaction of sensitive header values and JSON body keys. The single place that
/// decides what a log line may not contain.
public struct Redactor: Sendable {

    /// Lower-cased header names whose value is always replaced, on top of ``NetworkConfiguration``'s.
    public static let alwaysRedactedHeaders: Set<String> = [
        "authorization", "proxy-authorization", "cookie", "set-cookie",
    ]

    public static let placeholder = "***"

    private let headerDenylist: Set<String>
    private let bodyKeyDenylist: Set<String>

    /// - Parameters:
    ///   - redactedHeaders: additional header names (any case) to redact.
    ///   - redactedBodyKeys: JSON body keys (exact, case-sensitive) to redact.
    public init(redactedHeaders: Set<String> = [], redactedBodyKeys: Set<String> = []) {
        self.headerDenylist = Self.alwaysRedactedHeaders.union(redactedHeaders.map { $0.lowercased() })
        self.bodyKeyDenylist = redactedBodyKeys
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
