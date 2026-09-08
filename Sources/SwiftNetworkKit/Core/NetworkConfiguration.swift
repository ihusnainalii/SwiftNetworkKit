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

    // MARK: Authentication (M2)

    /// How `.required` endpoints get authenticated. Defaults to ``BearerAuth``.
    public var authorization: any AuthStrategy

    /// Where tokens live. Defaults to ``InMemoryTokenStorage``; swap for `KeychainTokenStorage`.
    public var tokenStorage: any TokenStorage

    /// Refresh a stored token this many seconds *before* its `expiresAt` (proactive refresh).
    public var proactiveRefreshLeeway: TimeInterval

    // MARK: Retry (M3)

    /// Client-wide retry policy. An ``Endpoint`` overrides it with ``Endpoint/retryPolicy``.
    public var retry: RetryPolicy

    /// The time source for every wait (backoff, `Retry-After`, proactive refresh). Tests inject a
    /// fake; production uses ``ContinuousClockAdapter``.
    public var clock: any NetworkClock

    // MARK: Interceptors, logging, metrics (M4)

    /// Run in order to adapt each outgoing request (after auth + tracing).
    public var requestInterceptors: [any RequestInterceptor]

    /// Run in reverse order to inspect each response (before status mapping).
    public var responseInterceptors: [any ResponseInterceptor]

    /// Correlation headers attached to every request. Defaults to a fresh `X-Request-ID` per request.
    public var tracing: TraceHeaders

    /// Where log lines go. Defaults to ``ConsoleNetworkLogger``; silence it via `environment.logLevel = .none`.
    public var logger: any NetworkLogger

    /// Observability sink. Defaults to ``NoopMetrics``; use ``InMemoryMetrics`` to aggregate.
    public var metrics: any NetworkMetrics

    // MARK: SSL pinning (M5)

    /// Certificate / public-key pinning. Defaults to ``SSLPinning/disabled`` (normal system TLS).
    /// A misconfigured value (missing resource, bad hash) fails `NetworkClient.init` loudly.
    public var sslPinning: SSLPinning

    // MARK: HTTP caching (M8)

    /// Response caching. Defaults to ``CacheConfiguration/disabled`` (no caching).
    public var cache: CacheConfiguration

    // MARK: Request management (M9)

    /// How many requests may run at once. Extra requests queue, ordered by ``Endpoint/priority``.
    /// Defaults to 6 (the `URLSession` per-host limit).
    public var maxConcurrentRequests: Int

    /// When `true`, concurrent identical `GET`/`HEAD` requests share one in-flight operation.
    /// An ``Endpoint`` can override with ``Endpoint/deduplicate``. Defaults to `false`.
    public var enableDeduplication: Bool

    // MARK: Offline queue (M11)

    /// Persistence for requests made offline by endpoints that opt into ``OfflineBehavior/queue(expiresAfter:)``.
    /// `nil` disables the offline queue. Requires ``networkMonitor`` too.
    public var offlineStore: (any OfflineStore)?

    /// Connectivity source. Used to fail-fast offline requests and to trigger offline-queue replay.
    public var networkMonitor: (any NetworkMonitor)?

    public init(
        environment: NetworkEnvironment,
        defaultDecoder: JSONDecoder = .networkKitDefault,
        defaultEncoder: JSONEncoder = .networkKitDefault,
        redactedHeaders: Set<String> = NetworkConfiguration.defaultRedactedHeaders,
        redactedBodyKeys: Set<String> = NetworkConfiguration.defaultRedactedBodyKeys,
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil,
        authorization: any AuthStrategy = BearerAuth(),
        tokenStorage: any TokenStorage = InMemoryTokenStorage(),
        proactiveRefreshLeeway: TimeInterval = 60,
        retry: RetryPolicy = .default,
        clock: any NetworkClock = ContinuousClockAdapter(),
        requestInterceptors: [any RequestInterceptor] = [],
        responseInterceptors: [any ResponseInterceptor] = [],
        tracing: TraceHeaders = TraceHeaders(),
        logger: any NetworkLogger = ConsoleNetworkLogger(),
        metrics: any NetworkMetrics = NoopMetrics(),
        sslPinning: SSLPinning = .disabled,
        cache: CacheConfiguration = .disabled,
        maxConcurrentRequests: Int = 6,
        enableDeduplication: Bool = false,
        offlineStore: (any OfflineStore)? = nil,
        networkMonitor: (any NetworkMonitor)? = nil
    ) {
        self.environment = environment
        self.defaultDecoder = defaultDecoder
        self.defaultEncoder = defaultEncoder
        self.redactedHeaders = Set(redactedHeaders.map { $0.lowercased() })
        self.redactedBodyKeys = redactedBodyKeys
        self.errorMapper = errorMapper
        self.authorization = authorization
        self.tokenStorage = tokenStorage
        self.proactiveRefreshLeeway = proactiveRefreshLeeway
        self.retry = retry
        self.clock = clock
        self.requestInterceptors = requestInterceptors
        self.responseInterceptors = responseInterceptors
        self.tracing = tracing
        self.logger = logger
        self.metrics = metrics
        self.sslPinning = sslPinning
        self.cache = cache
        self.maxConcurrentRequests = maxConcurrentRequests
        self.enableDeduplication = enableDeduplication
        self.offlineStore = offlineStore
        self.networkMonitor = networkMonitor
    }

    /// Convenience single-environment initializer.
    public init(
        baseURL: URL,
        headers: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        authorization: any AuthStrategy = BearerAuth(),
        tokenStorage: any TokenStorage = InMemoryTokenStorage(),
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) {
        self.init(
            environment: NetworkEnvironment(
                kind: .production,
                baseURL: baseURL,
                defaultHeaders: headers,
                timeout: timeout
            ),
            errorMapper: errorMapper,
            authorization: authorization,
            tokenStorage: tokenStorage
        )
    }

    /// Convenience single-environment initializer taking a URL string.
    /// A malformed string is a programmer error and traps immediately.
    public init(
        baseURL string: String,
        headers: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        authorization: any AuthStrategy = BearerAuth(),
        tokenStorage: any TokenStorage = InMemoryTokenStorage(),
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) {
        guard let url = URL(string: string) else {
            preconditionFailure(#"NetworkConfiguration: invalid baseURL string "\#(string)""#)
        }
        self.init(
            baseURL: url,
            headers: headers,
            timeout: timeout,
            authorization: authorization,
            tokenStorage: tokenStorage,
            errorMapper: errorMapper
        )
    }

    public static let defaultRedactedHeaders: Set<String> = [
        "authorization", "proxy-authorization", "cookie", "set-cookie", "x-api-key",
    ]

    public static let defaultRedactedBodyKeys: Set<String> = [
        "password", "passwd", "secret", "token", "access_token", "refresh_token",
        "id_token", "client_secret", "authorization",
    ]
}
