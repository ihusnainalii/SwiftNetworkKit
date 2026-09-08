import Foundation

#if canImport(Security)
import Security
#endif

/// A per-request task delegate for ``URLSessionTransport/data(for:)``: it answers the server-trust
/// challenge (SSL pinning) and records a rejection so the transport can surface the real
/// ``NetworkError/sslPinningFailed(host:)`` instead of a bare cancellation.
///
/// Upload/download use ``TransportSessionDelegate`` instead — the async `data(for:delegate:)` family
/// does not reliably forward byte-progress callbacks to a per-task delegate.
final class TransportTaskDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    #if canImport(Security)
    private let evaluator: (any ServerTrustEvaluating)?
    #endif

    private let lock = NSLock()
    private var _failure: NetworkError?
    var recordedFailure: NetworkError? { lock.withLock { _failure } }

    #if canImport(Security)
    init(evaluator: (any ServerTrustEvaluating)?) {
        self.evaluator = evaluator
    }
    #else
    override init() {}
    #endif

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
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
}
