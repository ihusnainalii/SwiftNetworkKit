import Foundation

/// The default ``NetworkTransport``, backed by `URLSession`.
///
/// `@unchecked Sendable`: it holds a `URLSession`, which is thread-safe. Each request runs with a
/// fresh per-task ``TransportTaskDelegate`` that answers the server-trust challenge (SSL pinning) and
/// forwards upload/download byte progress. A rejected pin surfaces as
/// ``NetworkError/sslPinningFailed(host:)`` rather than a bare cancellation.
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

    private func makeDelegate(
        onProgress: (@Sendable (ProgressEvent) -> Void)? = nil
    ) -> TransportTaskDelegate {
        #if canImport(Security)
        return TransportTaskDelegate(evaluator: trustEvaluator, onProgress: onProgress)
        #else
        return TransportTaskDelegate(onProgress: onProgress)
        #endif
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let delegate = makeDelegate()
        do {
            let (data, response) = try await session.data(for: request, delegate: delegate)
            return (data, try Self.http(response))
        } catch let error as NetworkError {
            throw error
        } catch {
            throw delegate.recordedFailure ?? NetworkError.normalize(error)
        }
    }

    public func upload(
        _ request: URLRequest,
        from body: UploadBody,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = request
        let delegate = makeDelegate(onProgress: progress)
        do {
            let (data, response): (Data, URLResponse)
            switch body {
            case .data(let payload):
                (data, response) = try await session.upload(for: request, from: payload, delegate: delegate)
            case .file(let url):
                (data, response) = try await session.upload(for: request, fromFile: url, delegate: delegate)
            case .multipart(let form):
                if request.value(forHTTPHeaderField: "Content-Type") == nil {
                    request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
                }
                let fileURL = FileManager.default.temporaryDirectory
                    .appendingPathComponent("swiftnetworkkit-upload-\(UUID().uuidString)")
                do { try form.writeEncoded(to: fileURL) }
                catch let error as NetworkError { throw error }
                catch { throw NetworkError.encoding(underlying: asSendableError(error)) }
                defer { try? FileManager.default.removeItem(at: fileURL) }
                (data, response) = try await session.upload(for: request, fromFile: fileURL, delegate: delegate)
            }
            return (data, try Self.http(response))
        } catch let error as NetworkError {
            throw error
        } catch {
            throw delegate.recordedFailure ?? NetworkError.normalize(error)
        }
    }

    public func download(
        _ request: URLRequest,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (URL, HTTPURLResponse) {
        let delegate = makeDelegate(onProgress: progress)
        do {
            let (returnedURL, response) = try await session.download(for: request, delegate: delegate)
            let fileURL = delegate.downloadedFile ?? returnedURL
            return (fileURL, try Self.http(response))
        } catch let error as NetworkError {
            throw error
        } catch {
            throw delegate.recordedFailure ?? NetworkError.normalize(error)
        }
    }

    private static func http(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport(underlying: URLError(.badServerResponse))
        }
        return httpResponse
    }
}
