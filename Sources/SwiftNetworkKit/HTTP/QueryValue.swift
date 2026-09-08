/// A typed value for a URL query parameter.
public enum QueryValue: Sendable, Hashable {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    /// Repeated key: `?tag=a&tag=b`.
    case list([String])

    /// The individual string renderings this value expands to (one per emitted query item).
    var renderings: [String] {
        switch self {
        case .string(let value): [value]
        case .int(let value): [String(value)]
        case .double(let value): [String(value)]
        case .bool(let value): [value ? "true" : "false"]
        case .list(let values): values
        }
    }
}
