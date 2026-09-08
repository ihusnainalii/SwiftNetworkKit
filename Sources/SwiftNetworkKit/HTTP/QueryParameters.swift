import Foundation

/// An ordered set of URL query parameters.
///
/// Order is preserved. A `nil` value omits the key entirely. `+` is percent-encoded as `%2B`
/// (`URLComponents` alone leaves it as a literal `+`, which servers read as a space).
public struct QueryParameters: Sendable, Hashable, ExpressibleByDictionaryLiteral {

    public struct Item: Sendable, Hashable {
        public var name: String
        public var value: QueryValue?
    }

    public private(set) var items: [Item]

    public init() {
        items = []
    }

    public init(_ pairs: [(String, QueryValue?)]) {
        items = pairs.map { Item(name: $0.0, value: $0.1) }
    }

    public init(dictionaryLiteral elements: (String, QueryValue?)...) {
        items = elements.map { Item(name: $0.0, value: $0.1) }
    }

    /// Appends a parameter, preserving insertion order (and allowing intentional duplicates).
    public mutating func append(_ name: String, _ value: QueryValue?) {
        items.append(Item(name: name, value: value))
    }

    /// `URLQueryItem`s with `nil` values dropped and list values expanded to repeated keys.
    /// Values are *not* percent-encoded here — see ``percentEncodedQueryString()``.
    public func queryItems() -> [URLQueryItem] {
        var result: [URLQueryItem] = []
        for item in items {
            guard let value = item.value else { continue }
            for rendering in value.renderings {
                result.append(URLQueryItem(name: item.name, value: rendering))
            }
        }
        return result
    }

    /// A fully percent-encoded `a=b&c=d` string, or `nil` when there are no parameters.
    /// `+`, `&`, `=` and `?` are always encoded in names and values.
    public func percentEncodedQueryString() -> String? {
        let allowed = CharacterSet.urlQueryAllowed.subtracting(CharacterSet(charactersIn: "+&=?"))
        let parts: [String] = queryItems().map { item in
            let name = item.name.addingPercentEncoding(withAllowedCharacters: allowed) ?? item.name
            let value = (item.value ?? "").addingPercentEncoding(withAllowedCharacters: allowed) ?? ""
            return "\(name)=\(value)"
        }
        return parts.isEmpty ? nil : parts.joined(separator: "&")
    }
}
