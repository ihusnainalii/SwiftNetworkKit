import Foundation

/// The outcome of asking "should this failed attempt be retried, and after how long?".
public enum RetryDecision: Sendable, Equatable {
    /// Wait `after` seconds (backoff or `Retry-After`, jitter already applied) then try again.
    case retry(after: TimeInterval)
    /// Give up — surface the error to the caller.
    case stop

    /// Decides based on the effective policy, the request method, which attempt just failed
    /// (1-indexed), and the error it failed with.
    static func evaluate(
        policy: RetryPolicy,
        method: HTTPMethod,
        attempt: Int,
        error: NetworkError
    ) -> RetryDecision {
        guard attempt < policy.maxAttempts else { return .stop }
        guard method.isIdempotent || policy.retryNonIdempotent else { return .stop }

        func backoff() -> RetryDecision {
            .retry(after: policy.backoff.delay(forAttempt: attempt, jitter: policy.jitter))
        }

        switch error {
        case .rateLimited(let retryAfter, _):
            guard policy.retryableStatusCodes.contains(429) else { return .stop }
            if policy.respectRetryAfter, let retryAfter {
                return .retry(after: min(retryAfter, policy.maxRetryAfterDelay))
            }
            return backoff()

        case .server(let context):
            return policy.retryableStatusCodes.contains(context.statusCode) ? backoff() : .stop

        case .unacceptableStatusCode(let code, _):
            return policy.retryableStatusCodes.contains(code) ? backoff() : .stop

        case .timeout:
            let retryable =
                policy.retryableStatusCodes.contains(408)
                || policy.retryableURLErrorCodes.contains(.timedOut)
            return retryable ? backoff() : .stop

        case .noInternet:
            // `NetworkError.normalize` folds these URLError codes into `.noInternet`.
            let family: Set<URLError.Code> = [
                .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed,
            ]
            return policy.retryableURLErrorCodes.isDisjoint(with: family) ? .stop : backoff()

        case .transport(let underlying):
            guard let urlError = underlying as? URLError,
                policy.retryableURLErrorCodes.contains(urlError.code)
            else { return .stop }
            return backoff()

        default:
            return .stop
        }
    }
}
