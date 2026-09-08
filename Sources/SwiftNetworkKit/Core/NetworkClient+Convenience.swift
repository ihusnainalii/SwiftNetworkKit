import Foundation

/// A handle for cancelling an in-flight request started via a completion-handler call.
public struct NetworkCancellable: Sendable {
    private let _cancel: @Sendable () -> Void

    public init(_ cancel: @escaping @Sendable () -> Void) {
        _cancel = cancel
    }

    /// Cancels the underlying `Task`. Safe to call more than once.
    public func cancel() {
        _cancel()
    }
}

public extension NetworkClient {

    // MARK: Completion-handler bridge

    /// Completion-handler variant of ``request(_:)`` for call sites that aren't `async`.
    ///
    /// The completion may be invoked on any executor — hop to the main actor yourself for UI.
    @discardableResult
    func request<E: Endpoint>(
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
    func data(for endpoint: some Endpoint) async throws -> Data {
        try await perform(endpoint) { data, _, _ in data }
    }

    /// Sends the endpoint and returns the response body decoded as a UTF-8 string.
    func string(for endpoint: some Endpoint) async throws -> String {
        try await perform(endpoint) { data, _, _ in
            guard let string = String(data: data, encoding: .utf8) else {
                throw NetworkError.decoding(underlying: EndpointDecodingFailure.responseNotUTF8, nil)
            }
            return string
        }
    }

    /// Sends the endpoint and discards the body (for writes whose response you don't need).
    func send(_ endpoint: some Endpoint) async throws {
        _ = try await perform(endpoint) { _, _, _ in EmptyResponse() }
    }
}
