# Retry and resilience

Idempotency-aware retries with exponential backoff, jitter, and `Retry-After` support.

## Overview

``NetworkConfiguration`` `retry` holds a ``RetryPolicy``. It applies to every request unless
an endpoint overrides it with `var retryPolicy: RetryPolicy? { ... }`.

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.retry = RetryPolicy(
    maxAttempts: 3,
    retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    backoff: .exponential(base: 0.3, multiplier: 2, maxDelay: 20),
    jitter: .equal,
    respectRetryAfter: true
)
```

## What gets retried

- Retryable status codes (`5xx`, `429`, `408` by default).
- Transient `URLError`s (`.timedOut`, `.networkConnectionLost`, `.notConnectedToInternet`,
  `.dnsLookupFailed`, `.cannotConnectToHost`).
- **Idempotent methods only** (`GET`, `HEAD`, `PUT`, `DELETE`, …). `POST` / `PATCH` are not
  retried unless `retryNonIdempotent` is set or the endpoint opts in.

## Backoff

``BackoffStrategy`` `.exponential(base:multiplier:maxDelay:)` yields `base`, `base·m`,
`base·m²`, … capped at `maxDelay`. ``Jitter`` spreads the delay to avoid a thundering herd:

| ``Jitter`` | Delay |
|---|---|
| `.none` | exactly the backoff value |
| `.full` | `random(0 ... backoff)` |
| `.equal` | `backoff/2 + random(0 ... backoff/2)` |

## Rate limiting

When `respectRetryAfter` is on, a `429` (or `503`) with a `Retry-After` header waits that
long instead of the computed backoff, clamped to `maxRetryAfterDelay`. A hostile or
malformed header cannot stall the client indefinitely; the value is bounded.

The error surfaced when retries are exhausted is
``NetworkError/rateLimited(retryAfter:_:)`` for a `429`, otherwise the mapped status error.
Callers can ask ``NetworkError/isRetryable`` whether re-attempting could plausibly help.

## Testing backoff

Inject a ``TestClock`` as ``NetworkConfiguration`` `clock` to advance time deterministically
in tests without real sleeps (see <doc:Testing>).
