import Foundation

/// What a ``ResponseInterceptor`` wants the pipeline to do with a response.
public enum InterceptOutcome: Sendable {
    /// Nothing to do — carry on to status mapping and decoding.
    case proceed
    /// Re-send the request after `after` seconds. Capped at 2 interceptor-driven retries per request,
    /// independent of ``RetryPolicy``.
    case retry(after: TimeInterval)
    /// Fail the request now with this error.
    case fail(NetworkError)
    /// Replace the response body with `Data` and proceed (status code unchanged).
    case substitute(Data)
}
