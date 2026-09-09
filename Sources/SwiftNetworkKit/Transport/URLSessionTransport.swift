#if !os(WASI)  // URLSession is unavailable on WebAssembly; inject a NetworkTransport instead.
import Foundation

/// The default ``NetworkTransport``, backed by `URLSession`.
///
/// `@unchecked Sendable`: it holds a `URLSession`, which is thread-safe. `data(for:)` runs on the
/// shared session with a per-request ``TransportTaskDelegate`` for the server-trust challenge
/// (SSL pinning). `upload` / `download` each spin up a short-lived session with a
/// ``TransportSessionDelegate`` so byte-progress callbacks are delivered reliably. A rejected pin
/// surfaces as ``NetworkError/sslPinningFailed(host:)`` rather than a bare cancellation.
public final class URLSessionTransport: NetworkTransport, @unchecked Sendable {

    private let session: URLSession
    private let baseConfiguration: URLSessionConfiguration
    #if canImport(Security)
    private let trustEvaluator: (any ServerTrustEvaluating)?
    #endif

    public init(session: URLSession) {
        self.session = session
        self.baseConfiguration = session.configuration
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
        self.baseConfiguration = configuration
        self.trustEvaluator = trustEvaluator
    }
    #endif

    deinit {
        session.finishTasksAndInvalidate()
    }

    // MARK: data

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let delegate = makeTaskDelegate()
        do {
            let (data, response) = try await session.data(for: request, delegate: delegate)
            return (data, try Self.http(response))
        } catch let error as NetworkError {
            throw error
        } catch {
            throw delegate.recordedFailure ?? NetworkError.normalize(error)
        }
    }

    // MARK: upload

    public func upload(
        _ request: URLRequest,
        from body: UploadBody,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = request
        var scratchFile: URL?
        defer { scratchFile.map { try? FileManager.default.removeItem(at: $0) } }

        let sourceFile: URL?
        let inlineData: Data?
        switch body {
        case .data(let payload):
            inlineData = payload
            sourceFile = nil
        case .file(let url):
            inlineData = nil
            sourceFile = url
        case .multipart(let form):
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            }
            let url = FileManager.default.temporaryDirectory
                .appendingPathComponent("swiftnetworkkit-upload-\(UUID().uuidString)")
            do { try form.writeEncoded(to: url) } catch let error as NetworkError { throw error } catch {
                throw NetworkError.encoding(underlying: asSendableError(error))
            }
            scratchFile = url
            sourceFile = url
            inlineData = nil
        }

        let delegate = makeSessionDelegate(onProgress: progress)
        let session = URLSession(configuration: baseConfiguration, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        try await runTask(session: session, delegate: delegate) {
            if let inlineData {
                return session.uploadTask(with: request, from: inlineData)
            }
            return session.uploadTask(with: request, fromFile: sourceFile!)
        }

        guard let response = delegate.httpResponse else {
            throw NetworkError.transport(underlying: URLError(.badServerResponse))
        }
        return (delegate.responseBody, response)
    }

    // MARK: download

    public func download(
        _ request: URLRequest,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (URL, HTTPURLResponse) {
        let delegate = makeSessionDelegate(onProgress: progress)
        let session = URLSession(configuration: baseConfiguration, delegate: delegate, delegateQueue: nil)
        defer { session.finishTasksAndInvalidate() }

        try await runTask(session: session, delegate: delegate) {
            session.downloadTask(with: request)
        }

        guard let response = delegate.httpResponse, let fileURL = delegate.downloadedFile else {
            throw NetworkError.transport(underlying: URLError(.cannotOpenFile))
        }
        return (fileURL, response)
    }

    // MARK: helpers

    private func makeTaskDelegate() -> TransportTaskDelegate {
        #if canImport(Security)
        return TransportTaskDelegate(evaluator: trustEvaluator)
        #else
        return TransportTaskDelegate()
        #endif
    }

    private func makeSessionDelegate(
        onProgress: (@Sendable (ProgressEvent) -> Void)?
    ) -> TransportSessionDelegate {
        #if canImport(Security)
        return TransportSessionDelegate(evaluator: trustEvaluator, onProgress: onProgress)
        #else
        return TransportSessionDelegate(onProgress: onProgress)
        #endif
    }

    /// Runs one task built by `makeTask` to completion, honoring task cancellation, and maps a
    /// pinning rejection to the real error.
    private func runTask(
        session: URLSession,
        delegate: TransportSessionDelegate,
        makeTask: () -> URLSessionTask
    ) async throws {
        let task = makeTask()
        do {
            try await withTaskCancellationHandler {
                try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                    delegate.completion = { result in continuation.resume(with: result) }
                    task.resume()
                }
            } onCancel: {
                task.cancel()
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw delegate.pinningFailure ?? NetworkError.normalize(error)
        }
    }

    private static func http(_ response: URLResponse) throws -> HTTPURLResponse {
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.transport(underlying: URLError(.badServerResponse))
        }
        return httpResponse
    }
}
#endif
