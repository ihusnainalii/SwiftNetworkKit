import Foundation

/// Value-typed retry configuration. Lives on ``NetworkConfiguration`` as the client-wide default;
/// an ``Endpoint`` can override it wholesale via ``Endpoint/retryPolicy``.
///
/// Retries are **idempotency-aware**: `GET`, `HEAD`, `PUT`, `DELETE`, `OPTIONS` and `TRACE` retry;
/// `POST`, `PATCH` and `.custom` methods do **not**, unless ``retryNonIdempotent`` is set.
public struct RetryPolicy: Sendable, Hashable {

    /// Total attempts including the first. `1` disables retrying.
    public var maxAttempts: Int

    /// HTTP status codes that are worth retrying.
    public var retryableStatusCodes: Set<Int>

    /// `URLError` codes (surfaced as `.timeout` / `.noInternet` / `.transport`) worth retrying.
    public var retryableURLErrorCodes: Set<URLError.Code>

    /// How the wait between attempts grows.
    public var backoff: BackoffStrategy

    /// Randomness applied to each computed backoff delay.
    public var jitter: Jitter

    /// Honor a server `Retry-After` header on `429`/`503` instead of the computed backoff.
    public var respectRetryAfter: Bool

    /// Cap applied to a `Retry-After` value (a hostile or broken server can send an absurd one).
    public var maxRetryAfterDelay: TimeInterval

    /// Retry `POST`/`PATCH`/`.custom` too. Off by default — only turn on for endpoints you know are
    /// safe to repeat (or that carry an idempotency key).
    public var retryNonIdempotent: Bool

    public init(
        maxAttempts: Int = 3,
        retryableStatusCodes: Set<Int> = [408, 429, 500, 502, 503, 504],
        retryableURLErrorCodes: Set<URLError.Code> = [
            .timedOut, .networkConnectionLost, .notConnectedToInternet,
            .dnsLookupFailed, .cannotConnectToHost,
        ],
        backoff: BackoffStrategy = .exponential(),
        jitter: Jitter = .equal,
        respectRetryAfter: Bool = true,
        maxRetryAfterDelay: TimeInterval = 120,
        retryNonIdempotent: Bool = false
    ) {
        self.maxAttempts = max(1, maxAttempts)
        self.retryableStatusCodes = retryableStatusCodes
        self.retryableURLErrorCodes = retryableURLErrorCodes
        self.backoff = backoff
        self.jitter = jitter
        self.respectRetryAfter = respectRetryAfter
        self.maxRetryAfterDelay = maxRetryAfterDelay
        self.retryNonIdempotent = retryNonIdempotent
    }

    /// 3 attempts, exponential 0.5s backoff, equal jitter, honors `Retry-After`.
    public static let `default` = RetryPolicy()

    /// A single attempt — no retrying.
    public static let none = RetryPolicy(maxAttempts: 1)

    /// 5 attempts, faster ramp (0.3s base), for flaky-but-cheap idempotent reads.
    public static let aggressive = RetryPolicy(
        maxAttempts: 5,
        backoff: .exponential(base: 0.3, multiplier: 2, maxDelay: 20)
    )
}
