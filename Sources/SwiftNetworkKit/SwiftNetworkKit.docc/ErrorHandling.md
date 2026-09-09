# Error handling

One error type crosses the public boundary: ``NetworkError``.

## Overview

`URLError`, `DecodingError`, keychain `OSStatus`, and trust-evaluation failures are all
mapped to a ``NetworkError`` case before they reach you. `catch` it directly.

```swift
do {
    let user = try await client.request(GetProfile())
} catch let error as NetworkError {
    switch error {
    case .unauthorized, .sessionExpired: await router.logOut()
    case .noInternet, .offline:           showOfflineBanner()
    case .rateLimited(let retryAfter, _): scheduleRetry(after: retryAfter)
    default:                              showAlert(error.localizedDescription)
    }
}
```

## The cases

| Case | Meaning |
|---|---|
| ``NetworkError/invalidURL(_:)`` | the composed URL could not be formed |
| ``NetworkError/noInternet`` / ``NetworkError/offline`` | no connectivity |
| ``NetworkError/timeout`` | the request timed out |
| ``NetworkError/unauthorized(_:)`` | `401` (after refresh, if configured) |
| ``NetworkError/forbidden(_:)`` | `403` |
| ``NetworkError/notFound(_:)`` | `404` |
| ``NetworkError/validation(_:)`` | `422` or other 4xx validation |
| ``NetworkError/rateLimited(retryAfter:_:)`` | `429`, with the parsed `Retry-After` |
| ``NetworkError/server(_:)`` | `5xx` |
| ``NetworkError/unacceptableStatusCode(_:_:)`` | an out-of-range status |
| ``NetworkError/decoding(underlying:_:)`` | the body did not decode |
| ``NetworkError/encoding(underlying:)`` | the request body did not encode |
| ``NetworkError/sslPinningFailed(host:)`` | a pinned host failed evaluation |
| ``NetworkError/tokenRefreshFailed(underlying:)`` | the refresh handler threw |
| ``NetworkError/sessionExpired`` | refresh failed or a request 401'd twice |
| ``NetworkError/cancelled`` | the task or request was cancelled |
| ``NetworkError/offlineQueued(_:)`` | persisted for replay (see <doc:OfflineQueue>) |
| ``NetworkError/transport(underlying:)`` | a lower-level networking failure |
| ``NetworkError/unknown(underlying:)`` | anything unmapped |

## Inspecting a failure

- ``NetworkError/code`` - a stable, `Equatable` discriminant for `switch`ing and tests.
- ``NetworkError/statusCode``, ``NetworkError/responseHeaders``, ``NetworkError/responseData``,
  ``NetworkError/serverMessage`` - the response context, when the error came from one.
- ``NetworkError/isRetryable`` - an advisory hint (transient, timeout, `5xx`, `429` → `true`;
  `4xx`, decode, pinning, auth → `false`). Independent of the automatic ``RetryPolicy``.
- ``NetworkError/normalize(_:)`` - map an arbitrary thrown error into a ``NetworkError``.
