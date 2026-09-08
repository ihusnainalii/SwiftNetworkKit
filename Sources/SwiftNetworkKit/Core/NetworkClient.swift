import Foundation

/// The public entry point. Compose it once, then call ``request(_:)`` (and friends) with your
/// ``Endpoint`` values — the client owns URL building, transport, status-code mapping and decoding.
///
/// **M1 scope:** the request pipeline is `build → send → map status → decode`. Authentication (M2),
/// retry/backoff (M3), interceptors, logging and metrics (M4), caching (M8) and request management
/// (M9) wrap ``perform(_:decode:)`` as they land — the public API does not change.
public final class NetworkClient: Sendable {

    /// The configuration this client was created with.
    public let configuration: NetworkConfiguration

    private let transport: any NetworkTransport

    /// Creates a client.
    /// - Parameters:
    ///   - configuration: base URL, headers, timeout, decoders, redaction, error mapping.
    ///   - transport: injection seam for tests. Defaults to ``URLSessionTransport``.
    public init(configuration: NetworkConfiguration, transport: (any NetworkTransport)? = nil) {
        self.configuration = configuration
        self.transport = transport ?? URLSessionTransport(timeout: configuration.environment.timeout)
    }

    /// Sends the endpoint and decodes its ``Endpoint/Response``.
    public func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response {
        try await perform(endpoint) { data, response, decoder in
            try endpoint.decode(data, response: response, using: decoder)
        }
    }

    /// The shared pipeline. `decode` runs only on a 2xx/304 response; all failure mapping happens here.
    func perform<E: Endpoint, T: Sendable>(
        _ endpoint: E,
        decode: @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> T
    ) async throws -> T {
        do {
            try Task.checkCancellation()
        } catch {
            throw NetworkError.cancelled
        }

        let urlRequest = try RequestBuilder.build(
            endpoint: endpoint,
            environment: configuration.environment,
            configuration: configuration
        )

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
            throw error
        }

        let decoder = endpoint.decoder ?? configuration.defaultDecoder
        do {
            return try decode(data, response, decoder)
        } catch let error as NetworkError {
            // Enrich a context-less decoding failure from `Endpoint.decode` with the real response.
            if case .decoding(let underlying, nil) = error {
                throw NetworkError.decoding(underlying: underlying, context)
            }
            throw error
        } catch {
            throw NetworkError.decoding(underlying: asSendableError(error), context)
        }
    }
}
