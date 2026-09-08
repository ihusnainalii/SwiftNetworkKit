import Foundation

/// An HTTP request method. Covers the standard verbs plus an escape hatch for custom ones.
public enum HTTPMethod: Sendable, Hashable {
    case get
    case post
    case put
    case patch
    case delete
    case head
    case options
    case trace
    case custom(String)

    /// The wire representation, always upper-cased.
    public var rawValue: String {
        switch self {
        case .get: "GET"
        case .post: "POST"
        case .put: "PUT"
        case .patch: "PATCH"
        case .delete: "DELETE"
        case .head: "HEAD"
        case .options: "OPTIONS"
        case .trace: "TRACE"
        case .custom(let value): value.uppercased()
        }
    }

    /// Whether the method is safe to retry automatically without risking duplicate side effects.
    ///
    /// `POST` and `PATCH` are treated as non-idempotent. `custom` is conservatively non-idempotent —
    /// an endpoint can still opt a specific request into retrying via its retry policy (M3).
    public var isIdempotent: Bool {
        switch self {
        case .get, .head, .put, .delete, .options, .trace: true
        case .post, .patch, .custom: false
        }
    }

    /// Parses a method from a raw string, mapping unknown verbs to `.custom`.
    public init(rawValue: String) {
        switch rawValue.uppercased() {
        case "GET": self = .get
        case "POST": self = .post
        case "PUT": self = .put
        case "PATCH": self = .patch
        case "DELETE": self = .delete
        case "HEAD": self = .head
        case "OPTIONS": self = .options
        case "TRACE": self = .trace
        case let other: self = .custom(other)
        }
    }
}
