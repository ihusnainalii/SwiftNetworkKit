import Foundation

/// Whether — and how — a request needs authentication applied.
public enum AuthRequirement: Sendable {
    /// No authentication.
    case none
    /// Apply the client's configured ``AuthStrategy``, refreshing the token on a 401.
    case required
    /// Apply a specific strategy for this endpoint (still 401-refresh aware).
    case custom(any AuthStrategy)

    /// `true` for `.required` and `.custom`.
    public var isAuthenticated: Bool {
        switch self {
        case .none: false
        case .required, .custom: true
        }
    }
}

extension AuthRequirement: Equatable {
    /// Compares only the well-known cases; two `.custom` values are never considered equal
    /// (strategies aren't `Equatable`).
    public static func == (lhs: AuthRequirement, rhs: AuthRequirement) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.required, .required): true
        default: false
        }
    }
}

/// Relative scheduling hint for the request queue (M9). Best-effort — running requests aren't preempted.
public enum RequestPriority: Sendable, Comparable {
    case low
    case normal
    case high
}

/// A response body that is expected to be empty (204, or a write with no useful payload).
public struct EmptyResponse: Codable, Sendable, Hashable {
    public init() {}
}

/// One API operation, defined by the consuming app.
///
/// Conform an `enum` or `struct` per API. Almost everything has a default — a minimal endpoint is
/// just `path`, `method` (defaults to `.get`) and `typealias Response`.
///
/// ```swift
/// enum UserEndpoint: Endpoint {
///     case profile
///     var path: String { "/me" }
///     var authentication: AuthRequirement { .required }
///     typealias Response = User
/// }
/// ```
public protocol Endpoint: Sendable {
    /// The decoded result type. `Data`, `String`, ``EmptyResponse`` and any `Decodable` are handled
    /// by the default ``decode(_:response:using:)``.
    associatedtype Response: Sendable

    /// Overrides the environment's base URL for this endpoint only. `nil` = use the environment's.
    var baseURL: URL? { get }

    /// Path appended to the base URL. May contain `:name` tokens filled from ``pathParameters``.
    var path: String { get }

    var method: HTTPMethod { get }
    var headers: HTTPHeaders { get }
    var queryParameters: QueryParameters? { get }

    /// Values substituted into `:name` tokens in ``path``.
    var pathParameters: [String: String] { get }

    var body: RequestBody? { get }
    var authentication: AuthRequirement { get }

    /// Per-endpoint timeout override. `nil` = use the environment's.
    var timeout: TimeInterval? { get }

    var priority: RequestPriority { get }

    /// Per-endpoint decoder override. `nil` = use the client's default.
    var decoder: JSONDecoder? { get }

    /// Turns response bytes into ``Response``. The default handles `Data`, `String`,
    /// ``EmptyResponse`` and `Decodable`; override for anything bespoke.
    func decode(_ data: Data, response: HTTPURLResponse, using decoder: JSONDecoder) throws -> Response
}

public extension Endpoint {
    var baseURL: URL? { nil }
    var method: HTTPMethod { .get }
    var headers: HTTPHeaders { [:] }
    var queryParameters: QueryParameters? { nil }
    var pathParameters: [String: String] { [:] }
    var body: RequestBody? { nil }
    var authentication: AuthRequirement { .none }
    var timeout: TimeInterval? { nil }
    var priority: RequestPriority { .normal }
    var decoder: JSONDecoder? { nil }
}

/// Reasons the default decoder cannot produce a value.
public enum EndpointDecodingFailure: Error, Sendable, Equatable {
    case responseNotUTF8
    case unsupportedResponseType(String)
}

public extension Endpoint {
    func decode(_ data: Data, response: HTTPURLResponse, using decoder: JSONDecoder) throws -> Response {
        if Response.self == Data.self {
            return data as! Response
        }
        if Response.self == EmptyResponse.self {
            return EmptyResponse() as! Response
        }
        if Response.self == String.self {
            guard let string = String(data: data, encoding: .utf8) else {
                throw NetworkError.decoding(underlying: EndpointDecodingFailure.responseNotUTF8, nil)
            }
            return string as! Response
        }
        guard let decodableType = Response.self as? any Decodable.Type else {
            throw NetworkError.decoding(
                underlying: EndpointDecodingFailure.unsupportedResponseType(String(describing: Response.self)),
                nil
            )
        }
        do {
            let value = try decodableType.decodeFromJSON(data, using: decoder)
            return value as! Response
        } catch {
            throw NetworkError.decoding(underlying: asSendableError(error), nil)
        }
    }
}

private extension Decodable {
    static func decodeFromJSON(_ data: Data, using decoder: JSONDecoder) throws -> Self {
        try decoder.decode(Self.self, from: data)
    }
}
