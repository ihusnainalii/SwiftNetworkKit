import Foundation
#if canImport(Security)
import Security
#endif

/// A per-request `URLSession` delegate: answers the server-trust challenge (SSL pinning), forwards
/// upload/download byte progress, and — for downloads — moves the finished file somewhere stable
/// before `URLSession` deletes it.
///
/// Fresh per `data(for:)` / `upload(...)` / `download(...)` call, so there is no shared state to key
/// by task id.
final class TransportTaskDelegate: NSObject, URLSessionDownloadDelegate, @unchecked Sendable {

    #if canImport(Security)
    private let evaluator: (any ServerTrustEvaluating)?
    #endif
    private let onProgress: (@Sendable (ProgressEvent) -> Void)?

    private let lock = NSLock()
    private var _failure: NetworkError?
    private var _downloadedFile: URL?

    var recordedFailure: NetworkError? { lock.withLock { _failure } }
    var downloadedFile: URL? { lock.withLock { _downloadedFile } }

    #if canImport(Security)
    init(evaluator: (any ServerTrustEvaluating)? = nil, onProgress: (@Sendable (ProgressEvent) -> Void)? = nil) {
        self.evaluator = evaluator
        self.onProgress = onProgress
    }
    #else
    init(onProgress: (@Sendable (ProgressEvent) -> Void)? = nil) {
        self.onProgress = onProgress
    }
    #endif

    // MARK: Server trust (SSL pinning)

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        #if canImport(Security)
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust,
              let evaluator else {
            completionHandler(.performDefaultHandling, nil)
            return
        }
        let host = challenge.protectionSpace.host
        guard let trust = challenge.protectionSpace.serverTrust else {
            lock.withLock { _failure = .sslPinningFailed(host: host) }
            completionHandler(.cancelAuthenticationChallenge, nil)
            return
        }
        switch evaluator.evaluate(trust: trust, host: host) {
        case .success:
            completionHandler(.useCredential, URLCredential(trust: trust))
        case .failure(let error):
            lock.withLock { _failure = error }
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

    // MARK: Download completion

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        // URLSession deletes `location` the moment this returns — move it now, synchronously.
        let stable = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftnetworkkit-download-\(UUID().uuidString)")
        try? FileManager.default.moveItem(at: location, to: stable)
        lock.withLock { _downloadedFile = stable }
    }
}
