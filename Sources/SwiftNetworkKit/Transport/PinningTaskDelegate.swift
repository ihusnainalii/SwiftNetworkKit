import Foundation
#if canImport(Security)
import Security

/// A per-request `URLSession` task delegate that answers server-trust challenges with a
/// ``ServerTrustEvaluating``. Fresh per `data(for:)` call — no shared state to key by task id.
///
/// When it rejects a challenge the transport sees a generic cancellation; it reads
/// ``recordedFailure`` to surface the real ``NetworkError/sslPinningFailed(host:)``.
final class PinningTaskDelegate: NSObject, URLSessionTaskDelegate, @unchecked Sendable {

    private let evaluator: any ServerTrustEvaluating
    private let lock = NSLock()
    private var _failure: NetworkError?

    var recordedFailure: NetworkError? { lock.withLock { _failure } }

    init(evaluator: any ServerTrustEvaluating) {
        self.evaluator = evaluator
    }

    func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didReceive challenge: URLAuthenticationChallenge,
        completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void
    ) {
        guard challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust else {
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
    }
}
#endif
