import Foundation

/// The default ``NetworkTransport``, backed by `URLSession`.
///
/// `@unchecked Sendable`: it holds a `URLSession`, which is thread-safe. When an SSL-pinning
/// evaluator is supplied, each request runs with a fresh per-task delegate that answers the
/// server-trust challenge; a rejected pin surfaces as ``NetworkError/sslPinningFailed(host:)``
/// instead of a bare cancellation. Upload/download progress (M7) is introduced later.
public final class URLSessionTransport: NetworkTransport, @unchecked Sendable {

    private let session: URLSession
    #if canImport(Security)
    private let trustEvaluator: (any ServerTrustEvaluating)?
    #endif

    public init(session: URLSession) {
        self.session = session
        #if canImport(Security)
        self.trustEvaluator = nil
        #endif
    }

    public convenience init(
        timeout: TimeInterval = 60,
        configuration: URLSessionConfiguration = .default
    ) {
        configuration.timeoutIntervalForRequest = timeout
        self.init(session: URLSession(configuration: configuration))
    }

    #if canImport(Security)
    /// - Parameter trustEvaluator: answers server-trust challenges. `nil` = normal system TLS.
    public init(
        timeout: TimeInterval = 60,
        configuration: URLSessionConfiguration = .default,
        trustEvaluator: (any ServerTrustEvaluating)?
    ) {
        configuration.timeoutIntervalForRequest = timeout
        self.session = URLSession(configuration: configuration)
        self.trustEvaluator = trustEvaluator
    }
    #endif

    deinit {
        session.finishTasksAndInvalidate()
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        #if canImport(Security)
        let pinningDelegate = trustEvaluator.map(PinningTaskDelegate.init)
        #endif
        do {
            let data: Data
            let response: URLResponse
            #if canImport(Security)
            if let pinningDelegate {
                (data, response) = try await session.data(for: request, delegate: pinningDelegate)
            } else {
                (data, response) = try await session.data(for: request)
            }
            #else
            (data, response) = try await session.data(for: request)
            #endif
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.transport(underlying: URLError(.badServerResponse))
            }
            return (data, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch {
            #if canImport(Security)
            if let pinningFailure = pinningDelegate?.recordedFailure {
                throw pinningFailure
            }
            #endif
            throw NetworkError.normalize(error)
        }
    }
}
