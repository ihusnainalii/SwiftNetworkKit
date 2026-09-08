import Foundation

#if canImport(Security)
import Security
#endif

/// A session-level delegate driving one upload or download task to completion. Session-level (rather
/// than per-task) because the async `URLSession` upload/download methods do not reliably forward
/// `didSendBodyData` / `didWriteData` to a per-task delegate.
///
/// It answers the server-trust challenge (SSL pinning), forwards byte progress, accumulates the
/// upload response body, moves the finished download file before `URLSession` deletes it, and
/// resolves ``completion`` when the task ends.
final class TransportSessionDelegate: NSObject,
    URLSessionDataDelegate, URLSessionDownloadDelegate, @unchecked Sendable
{

    #if canImport(Security)
    private let evaluator: (any ServerTrustEvaluating)?
    #endif
    private let onProgress: (@Sendable (ProgressEvent) -> Void)?

    private let lock = NSLock()
    private var _body = Data()
    private var _fileURL: URL?
    private var _response: HTTPURLResponse?
    private var _pinFailure: NetworkError?

    /// Called exactly once when the task finishes.
    var completion: (@Sendable (Result<Void, any Error>) -> Void)?

    var responseBody: Data { lock.withLock { _body } }
    var downloadedFile: URL? { lock.withLock { _fileURL } }
    var httpResponse: HTTPURLResponse? { lock.withLock { _response } }
    var pinningFailure: NetworkError? { lock.withLock { _pinFailure } }

    #if canImport(Security)
    init(evaluator: (any ServerTrustEvaluating)?, onProgress: (@Sendable (ProgressEvent) -> Void)?) {
        self.evaluator = evaluator
        self.onProgress = onProgress
    }
    #else
    init(onProgress: (@Sendable (ProgressEvent) -> Void)?) {
        self.onProgress = onProgress
    }
    #endif

    // MARK: Server trust

    func urlSession(
        _ session: URLSession,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        #if canImport(Security)
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
            let evaluator
        else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let host = challenge.protectionSpace.host
        guard let trust = challenge.protectionSpace.serverTrust else {
            lock.withLock { _pinFailure = .sslPinningFailed(host: host) }
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        switch evaluator.evaluate(trust: trust, host: host) {
        case .success:
            completionHandler(.useCredential, URLCredential(trust: trust))
        case .failure(let error):
            lock.withLock { _pinFailure = error }
            completionHandler(.cancelAuthenticationChallenge, nil)
        }
        #else
        completionHandler(.performDefaultHandling, nil)
        #endif
    }

    // MARK: Progress

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didSendBodyData bytesSent: Int64,
        totalBytesSent: Int64,
        totalBytesExpectedToSend: Int64
    ) {
        onProgress?(ProgressEvent(completed: totalBytesSent, total: totalBytesExpectedToSend))
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        onProgress?(ProgressEvent(completed: totalBytesWritten, total: totalBytesExpectedToWrite))
    }

    // MARK: Upload response body

    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        lock.withLock { _body.append(data) }
    }

    // MARK: Download completion

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        let stable = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftnetworkkit-download-\(UUID().uuidString)")
        try? FileManager.default.moveItem(at: location, to: stable)
        lock.withLock { _fileURL = stable }
    }

    // MARK: Task completion

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: (any Error)?) {
        if let response = task.response as? HTTPURLResponse {
            lock.withLock { _response = response }
        }
        let completion = completion
        self.completion = nil
        if let error {
            completion?(.failure(error))
        } else {
            completion?(.success(()))
        }
    }
}
