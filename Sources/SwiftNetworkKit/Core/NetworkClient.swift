import Foundation

/// The public entry point. Compose it once, then call ``request(_:)`` (and friends) with your
/// ``Endpoint`` values — the client owns URL building, transport, authentication, status-code
/// mapping and decoding.
///
/// **M2 scope:** the pipeline is `build → authorize → send → map status → (401 ⇒ refresh + retry
/// once) → decode`. Retry/backoff (M3), interceptors/logging/metrics (M4), caching (M8) and request
/// management (M9) wrap ``perform(_:decode:)`` as they land — the public API does not change.
public final class NetworkClient: Sendable {

    /// The configuration this client was created with.
    public let configuration: NetworkConfiguration

    private let transport: any NetworkTransport

    /// Present only when a `refresh` handler was supplied; `nil` disables automatic token refresh.
    let tokenManager: TokenManager?

    /// Creates a client.
    /// - Parameters:
    ///   - configuration: base URL, headers, timeout, auth strategy, token storage, decoders.
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
    /// inside ``execute(_:requestID:decode:)`` and does not consume a retry attempt.
    func perform<E: Endpoint, T: Sendable>(
        _ endpoint: E,
        decode: @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> T
    ) async throws -> T {
        if Task.isCancelled { throw NetworkError.cancelled }
        let requestID = RequestID()
        let policy = endpoint.retryPolicy ?? configuration.retry
        var attempt = 1

        while true {
            do {
                let result = try await execute(endpoint, requestID: requestID, decode: decode)
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
                do {
                    try await configuration.clock.sleep(for: .seconds(delay))
                } catch {
                    await tokenManager?.forget(requestID)
                    throw NetworkError.cancelled
                }
                attempt += 1
            }
        }
    }

    private func execute<E: Endpoint, T: Sendable>(
        _ endpoint: E,
        requestID: RequestID,
        decode: @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> T
    ) async throws -> T {
        var urlRequest = try RequestBuilder.build(
            endpoint: endpoint,
            environment: configuration.environment,
            configuration: configuration
        )
        try await authorize(&urlRequest, for: endpoint)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.data(for: urlRequest)
        } catch {
            throw NetworkError.normalize(error)
        }

        let context = ResponseContext(
            statusCode: response.statusCode,
            headers: HTTPHeaders(response.allHeaderFields),
            data: data,
            request: urlRequest
        )

        if let error = StatusCodeMapper.map(context: context, errorMapper: configuration.errorMapper) {
            if error.code == .unauthorized, endpoint.authentication.isAuthenticated, let tokenManager {
                // Throws `.sessionExpired` on the second 401 for this request — no infinite loop.
                _ = try await tokenManager.refreshedToken(forRetryOf: requestID)
                return try await execute(endpoint, requestID: requestID, decode: decode)
            }
            throw error
        }

        let decoder = endpoint.decoder ?? configuration.defaultDecoder
        do {
            return try decode(data, response, decoder)
        } catch let error as NetworkError {
            if case .decoding(let underlying, nil) = error {
                throw NetworkError.decoding(underlying: underlying, context)
            }
            throw error
        } catch {
            throw NetworkError.decoding(underlying: asSendableError(error), context)
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
}
