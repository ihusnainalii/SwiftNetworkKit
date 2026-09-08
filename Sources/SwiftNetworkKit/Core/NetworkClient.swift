import Foundation

/// The public entry point. Compose it once, then call ``request(_:)`` (and friends) with your
/// ``Endpoint`` values — the client owns URL building, transport, authentication, status-code
/// mapping and decoding.
///
/// **Pipeline:** `build → authorize → trace → request-interceptors → send → response-interceptors →
/// map status → (401 ⇒ refresh + retry once) → decode`, wrapped in a ``RetryPolicy`` loop with
/// backoff. Logging (redacted) and metrics are emitted at each stage. Caching (M8) and request
/// management (M9) wrap ``perform(_:decode:)`` as they land — the public API does not change.
public final class NetworkClient: Sendable {

    /// The configuration this client was created with.
    public let configuration: NetworkConfiguration

    private let transport: any NetworkTransport
    private let interceptors: InterceptorChain
    private let logFormatter: NetworkLogFormatter

    /// Present only when a `refresh` handler was supplied; `nil` disables automatic token refresh.
    let tokenManager: TokenManager?

    /// Creates a client.
    /// - Parameters:
    ///   - configuration: base URL, headers, timeout, auth strategy, token storage, decoders,
    ///     retry policy, interceptors, logger, metrics.
    ///   - transport: injection seam for tests. Defaults to ``URLSessionTransport``.
    ///   - refresh: how to obtain a fresh ``TokenPair`` after a 401. Omit to disable auto-refresh.
    ///   - onSessionExpired: called once when a refresh fails or a request 401s twice.
    public init(
        configuration: NetworkConfiguration,
        transport: (any NetworkTransport)? = nil,
        refresh: TokenManager.RefreshHandler? = nil,
        onSessionExpired: @escaping TokenManager.SessionExpiredHandler = {}
    ) {
        self.configuration = configuration
        self.transport = transport ?? URLSessionTransport(timeout: configuration.environment.timeout)
        self.interceptors = InterceptorChain(
            requestInterceptors: [TracingInterceptor(configuration.tracing)] + configuration.requestInterceptors,
            responseInterceptors: configuration.responseInterceptors
        )
        self.logFormatter = NetworkLogFormatter(
            redactor: Redactor(
                redactedHeaders: configuration.redactedHeaders,
                redactedBodyKeys: configuration.redactedBodyKeys
            )
        )
        if let refresh {
            self.tokenManager = TokenManager(
                storage: configuration.tokenStorage,
                proactiveLeeway: configuration.proactiveRefreshLeeway,
                refresh: refresh,
                onSessionExpired: onSessionExpired
            )
        } else {
            self.tokenManager = nil
        }
    }

    /// Sends the endpoint and decodes its ``Endpoint/Response``.
    public func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        try await perform(endpoint) { data, response, decoder in
            try endpoint.decode(data, response: response, using: decoder)
        }
    }

    /// The shared pipeline. `decode` runs only on a 2xx/304 response; all failure mapping happens
    /// here, and retryable failures are re-attempted per the effective ``RetryPolicy`` with backoff
    /// waits routed through ``NetworkConfiguration/clock``. The 401 → refresh → retry hop lives
    /// inside `execute` and does not consume a retry attempt.
    func perform<E: Endpoint, T: Sendable>(
        _ endpoint: E,
        decode: @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> T
    ) async throws -> T {
        if Task.isCancelled { throw NetworkError.cancelled }
        let requestID = RequestID()
        let policy = endpoint.retryPolicy ?? configuration.retry
        var attempt = 1

        await configuration.metrics.record(.requestStarted(requestID))

        while true {
            do {
                let result = try await execute(
                    endpoint, requestID: requestID, interceptorRetries: 0, decode: decode
                )
                await tokenManager?.forget(requestID)
                return result
            } catch {
                let networkError = NetworkError.normalize(error)
                let decision = RetryDecision.evaluate(
                    policy: policy,
                    method: endpoint.method,
                    attempt: attempt,
                    error: networkError
                )
                guard case .retry(let delay) = decision, !Task.isCancelled else {
                    await tokenManager?.forget(requestID)
                    throw networkError
                }
                attempt += 1
                await configuration.metrics.record(.retry(requestID, attempt: attempt))
                do {
                    try await configuration.clock.sleep(for: .seconds(delay))
                } catch {
                    await tokenManager?.forget(requestID)
                    throw NetworkError.cancelled
                }
            }
        }
    }

    private func execute<E: Endpoint, T: Sendable>(
        _ endpoint: E,
        requestID: RequestID,
        interceptorRetries: Int,
        decode: @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> T
    ) async throws -> T {
        let anyEndpoint = AnyEndpoint(endpoint)

        var urlRequest = try RequestBuilder.build(
            endpoint: endpoint,
            environment: configuration.environment,
            configuration: configuration
        )
        try await authorize(&urlRequest, for: endpoint)
        urlRequest = try await interceptors.adapt(urlRequest, for: anyEndpoint)

        let started = configuration.clock.now()
        emit(logFormatter.requestLines(urlRequest, endpoint: anyEndpoint, level: logLevel), level: .basic)

        let rawData: Data
        let response: HTTPURLResponse
        do {
            (rawData, response) = try await transport.data(for: urlRequest)
        } catch {
            let mapped = NetworkError.normalize(error)
            await recordFailure(mapped, requestID: requestID, status: nil, since: started)
            throw mapped
        }

        var context = ResponseContext(
            statusCode: response.statusCode,
            headers: HTTPHeaders(response.allHeaderFields),
            data: rawData,
            request: urlRequest
        )

        switch try await interceptors.resolve(context, for: anyEndpoint) {
        case .proceed(let body):
            context = ResponseContext(
                statusCode: context.statusCode, headers: context.headers, data: body, request: urlRequest
            )
        case .fail(let error):
            await recordFailure(error, requestID: requestID, status: context.statusCode, since: started)
            throw error
        case .retry(let after) where interceptorRetries < 2:
            try await configuration.clock.sleep(for: .seconds(after))
            return try await execute(
                endpoint, requestID: requestID, interceptorRetries: interceptorRetries + 1, decode: decode
            )
        case .retry:
            break // interceptor-retry cap reached — proceed with the response we have
        }

        if let error = StatusCodeMapper.map(context: context, errorMapper: configuration.errorMapper) {
            if error.code == .unauthorized, endpoint.authentication.isAuthenticated, let tokenManager {
                do {
                    // Throws `.sessionExpired` on the second 401 for this request — no infinite loop.
                    _ = try await tokenManager.refreshedToken(forRetryOf: requestID)
                    await configuration.metrics.record(.tokenRefresh(success: true))
                } catch {
                    await configuration.metrics.record(.tokenRefresh(success: false))
                    await recordFailure(
                        NetworkError.normalize(error), requestID: requestID, status: nil, since: started
                    )
                    throw error
                }
                return try await execute(
                    endpoint, requestID: requestID, interceptorRetries: interceptorRetries, decode: decode
                )
            }
            await recordFailure(error, requestID: requestID, status: context.statusCode, since: started)
            throw error
        }

        let decoder = endpoint.decoder ?? configuration.defaultDecoder
        do {
            let value = try decode(context.data ?? Data(), response, decoder)
            await configuration.metrics.record(
                .success(requestID, duration: elapsed(since: started), status: context.statusCode)
            )
            emit(
                logFormatter.responseLines(context, duration: elapsed(since: started), level: logLevel),
                level: .basic
            )
            return value
        } catch let error as NetworkError {
            let mapped: NetworkError
            if case .decoding(let underlying, nil) = error {
                mapped = .decoding(underlying: underlying, context)
            } else {
                mapped = error
            }
            await recordFailure(mapped, requestID: requestID, status: context.statusCode, since: started)
            throw mapped
        } catch {
            let mapped = NetworkError.decoding(underlying: asSendableError(error), context)
            await recordFailure(mapped, requestID: requestID, status: context.statusCode, since: started)
            throw mapped
        }
    }

    private func authorize<E: Endpoint>(_ request: inout URLRequest, for endpoint: E) async throws {
        let strategy: any AuthStrategy
        switch endpoint.authentication {
        case .none:
            return
        case .required:
            strategy = configuration.authorization
        case .custom(let custom):
            strategy = custom
        }

        let token: String?
        if let tokenManager {
            token = await tokenManager.tokenForOutgoingRequest()
        } else {
            token = try? await configuration.tokenStorage.accessToken()
        }
        try await strategy.authorize(&request, token: token)
    }

    // MARK: - Logging & metrics helpers

    private var logLevel: LogLevel { configuration.environment.logLevel }

    private func elapsed(since start: ContinuousClock.Instant) -> Duration {
        start.duration(to: configuration.clock.now())
    }

    private func emit(_ lines: [String], level: LogLevel) {
        guard logLevel != .none, !lines.isEmpty else { return }
        for line in lines { configuration.logger.log(line, level: level) }
    }

    private func recordFailure(
        _ error: NetworkError, requestID: RequestID, status: Int?, since start: ContinuousClock.Instant
    ) async {
        await configuration.metrics.record(.failure(requestID, error, status: status ?? error.statusCode))
        if error.code == .timeout { await configuration.metrics.record(.timeout(requestID)) }
        if let line = logFormatter.failureLine(error, duration: elapsed(since: start), level: logLevel) {
            configuration.logger.log(line, level: .error)
        }
    }
}
