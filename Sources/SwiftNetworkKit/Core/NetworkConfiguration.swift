import Foundation

/// Central configuration for a `NetworkClient`.
///
/// **M0 scope note:** this holds the fields the request pipeline needs through milestone M1. Auth
/// (M2), retry (M3), interceptors/logging/metrics (M4), SSL pinning (M5), cache (M8), offline (M11)
/// and concurrency limits (M9) each add their fields here as their component protocols land — the
/// initializer keeps every field defaulted so consuming code never breaks on an addition.
public struct NetworkConfiguration: Sendable {

    /// The active environment (base URL, default headers, timeout, log level).
    public var environment: NetworkEnvironment

    /// Decoder used when an ``Endpoint`` does not supply its own.
    public var defaultDecoder: JSONDecoder

    /// Encoder used by ``RequestBody/json(_:encoder:)`` convenience callers by default.
    public var defaultEncoder: JSONEncoder

    /// Header names (case-insensitive) whose values must never appear in logs.
    public var redactedHeaders: Set<String>

    /// JSON body keys whose values must never appear in logs.
    public var redactedBodyKeys: Set<String>

    /// App hook to override status-code → error mapping. Consulted before the built-in mapping.
    public var errorMapper: (@Sendable (ResponseContext) -> NetworkError?)?

    public init(
        environment: NetworkEnvironment,
        defaultDecoder: JSONDecoder = .networkKitDefault,
        defaultEncoder: JSONEncoder = .networkKitDefault,
        redactedHeaders: Set<String> = NetworkConfiguration.defaultRedactedHeaders,
        redactedBodyKeys: Set<String> = NetworkConfiguration.defaultRedactedBodyKeys,
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) {
        self.environment = environment
        self.defaultDecoder = defaultDecoder
        self.defaultEncoder = defaultEncoder
        self.redactedHeaders = Set(redactedHeaders.map { $0.lowercased() })
        self.redactedBodyKeys = redactedBodyKeys
        self.errorMapper = errorMapper
    }

    /// Convenience single-environment initializer.
    public init(
        baseURL: URL,
        headers: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) {
        self.init(
            environment: NetworkEnvironment(
                kind: .production,
                baseURL: baseURL,
                defaultHeaders: headers,
                timeout: timeout
            ),
            errorMapper: errorMapper
        )
    }

    /// Convenience single-environment initializer taking a URL string.
    /// A malformed string is a programmer error and traps immediately.
    public init(
        baseURL string: String,
        headers: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) {
        guard let url = URL(string: string) else {
            preconditionFailure(#"NetworkConfiguration: invalid baseURL string "\#(string)""#)
        }
        self.init(baseURL: url, headers: headers, timeout: timeout, errorMapper: errorMapper)
    }

    public static let defaultRedactedHeaders: Set<String> = [
        "authorization", "proxy-authorization", "cookie", "set-cookie", "x-api-key",
    ]

    public static let defaultRedactedBodyKeys: Set<String> = [
        "password", "passwd", "secret", "token", "access_token", "refresh_token",
        "id_token", "client_secret", "authorization",
    ]
}
