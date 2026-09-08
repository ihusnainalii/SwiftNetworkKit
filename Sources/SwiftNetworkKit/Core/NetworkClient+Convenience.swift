import Foundation

extension NetworkClient {

    // MARK: Completion-handler bridge

    /// Completion-handler variant of ``request(_:)`` for call sites that aren't `async`.
    ///
    /// The completion may be invoked on any executor — hop to the main actor yourself for UI.
    @discardableResult
    public func request<E: Endpoint>(
        _ endpoint: E,
        completion: @escaping @Sendable (Result<E.Response, NetworkError>) -> Void
    ) -> NetworkCancellable {
        let task = Task {
            do {
                completion(.success(try await request(endpoint)))
            } catch {
                completion(.failure(NetworkError.normalize(error)))
            }
        }
        return NetworkCancellable { task.cancel() }
    }

    // MARK: Response-shape helpers

    /// Sends the endpoint and returns the raw response body.
    public func data<E: Endpoint>(for endpoint: E) async throws -> Data {
        try await queued(priority: endpoint.priority, skipQueue: endpoint.skipRequestQueue) { [self] in
            try await perform(endpoint) { data, _, _ in data }
        }
    }

    /// Sends the endpoint and returns the response body decoded as a UTF-8 string.
    public func string<E: Endpoint>(for endpoint: E) async throws -> String {
        try await queued(priority: endpoint.priority, skipQueue: endpoint.skipRequestQueue) { [self] in
            try await perform(endpoint) { data, _, _ in
                guard let string = String(data: data, encoding: .utf8) else {
                    throw NetworkError.decoding(underlying: EndpointDecodingFailure.responseNotUTF8, nil)
                }
                return string
            }
        }
    }

    /// Sends the endpoint and discards the body (for writes whose response you don't need).
    public func send<E: Endpoint>(_ endpoint: E) async throws {
        _ = try await queued(priority: endpoint.priority, skipQueue: endpoint.skipRequestQueue) { [self] in
            try await perform(endpoint) { _, _, _ in EmptyResponse() }
        }
    }
}
