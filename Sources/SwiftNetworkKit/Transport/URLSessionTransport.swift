import Foundation

/// The default ``NetworkTransport``, backed by `URLSession`.
///
/// `@unchecked Sendable`: it holds a `URLSession`, which is thread-safe. A `URLSessionDelegate` for
/// SSL pinning (M5) and upload/download progress (M7) is introduced with those milestones.
public final class URLSessionTransport: NetworkTransport, @unchecked Sendable {

    private let session: URLSession

    public init(session: URLSession) {
        self.session = session
    }

    public convenience init(
        timeout: TimeInterval = 60,
        configuration: URLSessionConfiguration = .default
    ) {
        configuration.timeoutIntervalForRequest = timeout
        self.init(session: URLSession(configuration: configuration))
    }

    deinit {
        session.finishTasksAndInvalidate()
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        do {
            let (data, response) = try await session.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse else {
                throw NetworkError.transport(underlying: URLError(.badServerResponse))
            }
            return (data, httpResponse)
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.normalize(error)
        }
    }
}
