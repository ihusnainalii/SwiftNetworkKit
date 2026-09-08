import Foundation

/// A case-insensitive collection of HTTP header fields.
///
/// Lookup and assignment ignore case (`headers["content-type"] == headers["Content-Type"]`), while the
/// most recently assigned spelling of each field name is preserved for the wire.
public struct HTTPHeaders: Sendable, Hashable, Codable, ExpressibleByDictionaryLiteral, Sequence {

    /// A single header field.
    public struct Element: Sendable, Hashable {
        public let name: String
        public let value: String
    }

    /// Keyed by lower-cased field name.
    private var storage: [String: Element]

    public init() {
        storage = [:]
    }

    public init(_ dictionary: [String: String]) {
        storage = [:]
        for (name, value) in dictionary { self[name] = value }
    }

    public init(dictionaryLiteral elements: (String, String)...) {
        storage = [:]
        for (name, value) in elements { self[name] = value }
    }

    /// Builds headers from an `HTTPURLResponse.allHeaderFields` dictionary.
    public init(_ responseHeaders: [AnyHashable: Any]) {
        storage = [:]
        for (key, value) in responseHeaders {
            guard let name = key as? String else { continue }
            self[name] = (value as? String) ?? String(describing: value)
        }
    }

    public subscript(_ name: String) -> String? {
        get { storage[name.lowercased()]?.value }
        set {
            let key = name.lowercased()
            if let newValue {
                storage[key] = Element(name: name, value: newValue)
            } else {
                storage[key] = nil
            }
        }
    }

    /// Appends a value to an existing field (comma-joined per RFC 9110), or sets it if absent.
    public mutating func add(name: String, value: String) {
        if let existing = self[name] {
            self[name] = existing + ", " + value
        } else {
            self[name] = value
        }
    }

    public enum MergeStrategy: Sendable {
        /// Keep this collection's value when both define a field.
        case keepCurrent
        /// Let the other collection's value win.
        case override
    }

    /// Returns a copy with `other` merged in according to `strategy`.
    public func merging(_ other: HTTPHeaders, strategy: MergeStrategy) -> HTTPHeaders {
        var result = self
        for element in other {
            switch strategy {
            case .override:
                result[element.name] = element.value
            case .keepCurrent:
                if result[element.name] == nil { result[element.name] = element.value }
            }
        }
        return result
    }

    /// A plain `[name: value]` snapshot using the preserved field-name spellings.
    public var dictionary: [String: String] {
        var out: [String: String] = [:]
        for element in storage.values { out[element.name] = element.value }
        return out
    }

    public var isEmpty: Bool { storage.isEmpty }
    public var count: Int { storage.count }

    public func makeIterator() -> AnyIterator<Element> {
        var iterator = storage.values.makeIterator()
        return AnyIterator { iterator.next() }
    }

    // MARK: Codable

    /// Encoded as a plain `[name: value]` object using the preserved field-name spellings.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        self.init(try container.decode([String: String].self))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(dictionary)
    }
}
