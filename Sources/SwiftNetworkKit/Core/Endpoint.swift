import Foundation

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

    /// Per-endpoint retry policy. `nil` = use the client's ``NetworkConfiguration/retry``. Set a
    /// policy with `retryNonIdempotent = true` here to opt a specific `POST`/`PATCH` into retrying.
    var retryPolicy: RetryPolicy? { get }

    /// Per-endpoint cache policy. `nil` = use ``NetworkConfiguration/cache``'s default. Only `GET`
    /// and `HEAD` responses are cached.
    var cachePolicy: CachePolicy? { get }

    /// Share one in-flight operation among concurrent identical requests. `nil` = use
    /// ``NetworkConfiguration/enableDeduplication``. Only ever applied to `GET`/`HEAD`.
    var deduplicate: Bool? { get }

    /// Bypass the concurrency queue (``NetworkConfiguration/maxConcurrentRequests``). Set this on a
    /// token-refresh endpoint so a full queue plus an expired token can't deadlock.
    var skipRequestQueue: Bool { get }

    /// What to do when this request is made offline. Defaults to ``OfflineBehavior/fail``. Requires
    /// ``NetworkConfiguration/offlineStore`` + ``NetworkConfiguration/networkMonitor`` to be set.
    var offlineBehavior: OfflineBehavior { get }

    /// Per-endpoint decoder override. `nil` = use the client's default.
    var decoder: JSONDecoder? { get }

    /// Turns response bytes into ``Response``. The default handles `Data`, `String`,
    /// ``EmptyResponse`` and `Decodable`; override for anything bespoke.
    func decode(_ data: Data, response: HTTPURLResponse, using decoder: JSONDecoder) throws -> Response
}

extension Endpoint {
    public var baseURL: URL? { nil }
    public var method: HTTPMethod { .get }
    public var headers: HTTPHeaders { [:] }
    public var queryParameters: QueryParameters? { nil }
    public var pathParameters: [String: String] { [:] }
    public var body: RequestBody? { nil }
    public var authentication: AuthRequirement { .none }
    public var timeout: TimeInterval? { nil }
    public var priority: RequestPriority { .normal }
    public var retryPolicy: RetryPolicy? { nil }
    public var cachePolicy: CachePolicy? { nil }
    public var deduplicate: Bool? { nil }
    public var skipRequestQueue: Bool { false }
    public var offlineBehavior: OfflineBehavior { .fail }
    public var decoder: JSONDecoder? { nil }
}

extension Endpoint {
    // Generic decode dispatch: each `as! Response` below is guarded by an exact
    // `Response.self == X.self` check on the preceding line, so the cast cannot fail.
    // swiftlint:disable force_cast
    public func decode(_ data: Data, response: HTTPURLResponse, using decoder: JSONDecoder) throws -> Response {
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
    // swiftlint:enable force_cast
}

extension Decodable {
    fileprivate static func decodeFromJSON(_ data: Data, using decoder: JSONDecoder) throws -> Self {
        try decoder.decode(Self.self, from: data)
    }
}
