# QA Review (post 1.0.0)

Consolidated findings from three independent review passes over `Sources/SwiftNetworkKit/`
run just after the 1.0.0 tag: a Swift 6 / concurrency review, a security review, and a
silent-failure / error-handling audit.

Status at review time: `swift build -warnings-as-errors` clean, 239 tests green, ThreadSanitizer
and AddressSanitizer clean, SwiftLint and swift-format `--strict` clean. Nothing here is a
release blocker. None reproduce as a failing test today; they are latent robustness, privacy,
and diagnosability gaps.

Verified sound (no action): pure-Swift SHA-256 vs NIST + RFC 7636 vectors, multipart injection
defence, path-parameter traversal defence, `TokenManager` single-flight refresh, retry
backoff/jitter math, `Endpoint.decode` casts, URLSession delegate lifetime (no retain cycle),
`Redactor` header/body scrubbing, TLS pin evaluation failing closed.

---

## 1. Cross-account data sharing (fix in 1.1, not breaking)

### 1a. Request-dedup key ignores token identity and is built pre-authorize
`RequestManagement/DeduplicationKey.swift` keys on `method + URL + presence of an Authorization
header`, not its value, and `NetworkClient.deduplicatedPerform` builds the key from
`RequestBuilder.build(...)` before `authorize(&urlRequest)` runs. Two concurrent authenticated
GETs to the same URL with different user tokens collapse to one in-flight task and share the
decoded result. Opt-in (`enableDeduplication` defaults false), GET/HEAD only, but a
data-disclosure bug in a multi-account app. The doc comment claims a safety property the code
does not provide.
Fix: include a hash of the Authorization value in the key; compute the key after authorize.

### 1b. Cache key ignores token identity; no logout hook
`Cache/ResponseCache.swift` cache key is `METHOD URL [+auth]` where `+auth` is a bare bool.
User A's cached authenticated `GET /me` is served to user B after a token swap
(`.cacheFirst` / `.staleWhileRevalidate` directly; `.networkFirst` on any network blip) until
TTL or eviction. `NetworkClient` exposes no `clearCache()`, so an app cannot flush on logout
through the client.
Fix: key on token identity; add `NetworkClient.clearCache()` and call it from `expireSession`.

---

## 2. Silent failures in the persistence and auth layers (fix in 1.1)

The theme: `try?` on write/read paths that have no other error channel.

| # | Location | Effect |
|---|---|---|
| 2a | `Offline/FileOfflineStore.swift` `save()` (`try?` throughout) | A failed queue write (disk full, data protection) is invisible; in-memory cache already updated, so the process looks healthy and the queued POST/PUT is gone on next launch. |
| 2b | `Offline/FileOfflineStore.swift` `load()` | Any JSON decode failure maps to `[]` and is cached as `loaded`; one bad byte or a wire-format change discards every pending replay with no diagnostic. Distinguish read-miss from decode-failure; log; move the bad file aside. |
| 2c | `Authentication/TokenManager.swift` `try? await storage.store(pair)` after refresh | A failed keychain write means every later request reloads the stale token, 401s, refreshes again, forever, with no log or metric. `store` already throws. |
| 2d | `Authentication/TokenManager.swift` `expireSession()` `try? await storage.clearTokenPair()` | Logout fires `onSessionExpired` (UI logs out) but tokens can remain on disk and be reused next launch. Security-relevant. |
| 2e | `TokenManager` / `NetworkClient` `guard let ... = try? await storage.currentTokenPair()` | `KeychainTokenStorage` correctly throws for real failures (`errSecInteractionNotAllowed` on a locked device, a corrupt-pair `DecodingError`); callers swallow it as "no token", so a transient locked keychain cascades into an unauthenticated request then a spurious permanent logout. Only treat `errSecItemNotFound` / nil as "no token". |
| 2f | `TokenManager` proactive refresh `return try? await performRefresh().accessToken` | `performRefresh()` on failure calls `expireSession()` (side-effecting logout) and throws `.tokenRefreshFailed(underlying:)`; the `try?` drops the error and the underlying cause. |
| 2g | `Core/NetworkClient.swift` `staleWhileRevalidate` `_ = try? await execute(...)` in the detached refresh task | No log, no metric, no `recordFailure`. If the endpoint starts permanently failing the client serves stale cache forever and nothing indicates revalidation is broken. |
| 2h | `Core/NetworkClient.swift` offline `return try? await offlineQueue.enqueue(...)` | If archiving or `store.append` fails, `execute` treats it as "no offline queue configured" and throws the raw network error instead of `.offlineQueued`; the caller cannot tell the request was dropped. |
| 2i | `Offline/OfflineRequestQueue.swift` unarchivable queued request | Removed from the store and emits nothing (unlike the `.expired` branch beside it, which emits `.expired`). A subscriber never learns their queued mutation vanished after a wire-format change. Add `.failed` / `.dropped`. |
| 2j | `Offline/OfflineRequestQueue.swift` replay | `persisted.attempts += 1` is stored but never read. A hard-failing transport-level request (e.g. permanent connection error) is re-run on every reconnect forever; only expiry removes it. Enforce a max-attempts drop / dead-letter. |

---

## 3. Privacy and logging (fix in 1.1)

### 3a. Request URLs logged unredacted at `.basic`
`Logging/NetworkLogFormatter.swift` logs `request.url?.absoluteString` verbatim; `Redactor`
only touches header values and JSON body keys, never the URL. The library itself ships
`APIKeyAuth(query:)` which appends the key as a query item, and `?access_token=` / signed URLs
are common. `NetworkConfiguration(baseURL:)` builds the environment with the memberwise default
`logLevel: .basic` (not the `.production()` factory that sets `.error`), and
`ConsoleNetworkLogger` writes `privacy: .public`, so a default-configured client logs every
request URL in production.
Fix: redact a configurable set of query-item names before logging (at minimum the
`APIKeyAuth(query:)` name); consider defaulting the convenience init to `.error`.

### 3b. Raw server bodies in error descriptions
`OAuthError.tokenRequestFailed(status:body:)` carries the raw token-endpoint body;
`NetworkError.errorDescription` interpolates `context.serverMessage` and underlying errors;
`ResponseContext.serverMessage` pulls `error_description` etc. from the body. None passes
through `Redactor`. An app logging `error.localizedDescription` can leak whatever a token / OAuth
endpoint echoes back. Document that error descriptions are not redaction-safe.

### 3c. `MetricEvent.failure` carries the full request/response
`Metrics/MetricEvent.swift` `.failure` carries a `NetworkError` whose `ResponseContext` holds the
`URLRequest` (with `Authorization`) and the raw response `data`. Shipped `InMemoryMetrics` /
`NoopMetrics` only keep counters, so no in-box leak, but a custom `NetworkMetrics` sink that
serializes events (Sentry / Datadog) exfiltrates the bearer token and body. Pass only
`NetworkError.Code` + status to metrics, or document the hazard.

### 3d. DiskCacheStore: weak filename hash, plaintext sensitive headers, no user isolation
`Cache/DiskCacheStore.swift` derives the on-disk filename with DJB2 and calls it
"collision-resistant"; DJB2 is trivially collidable, so an attacker who influences a cached URL
can craft a key that overwrites or serves another entry (cache poisoning). Use SHA-256.
Separately `NetworkClient.execute` writes the full `context.headers` into the JSON entry, so
`Set-Cookie` and auth-ish response headers persist in cleartext (`.completeFileProtectionUnlessOpen`
helps on iOS, is a no-op on macOS). Strip `set-cookie` / auth response headers before caching.

---

## 4. Concurrency and ordering (fix in 1.1)

### 4a. PathNetworkMonitor loses path-update ordering
`Connectivity/PathNetworkMonitor.swift` spawns an independent `Task { await broadcaster.publish(status) }`
per `pathUpdateHandler` callback. `NWPathMonitor` delivers serially but the unstructured tasks
race on the actor, so a rapid satisfied to unsatisfied to satisfied flap can leave the broadcaster
reporting `.unsatisfied` while the device is online, silently blocking requests as "offline" and
stalling offline-queue replay. Feed updates through a single serialized consumer.

### 4b. RequestQueue waiters not woken on cancellation
`RequestManagement/RequestQueue.swift` `acquire` parks in a plain `withCheckedContinuation` with
no `withTaskCancellationHandler`. A cancelled request keeps its slot in `waiters`, and `drain()`
hands it a running slot before `enqueue` notices `Task.isCancelled`. `cancel(id)` / `cancelAll()`
do not promptly free queue capacity; under load real requests wait behind dead ones.

### 4c. staleWhileRevalidate revalidation is unmanaged `Task.detached`
`Core/NetworkClient.swift` background refresh is a `Task.detached` that is not registered for
cancellation, bypasses `RequestQueue` and dedup, and captures `self` + `decode` strongly. Bursts
of SWR reads blow past `maxConcurrentRequests` and nothing can cancel them.

### 4d. Cancelled SwiftUI loads render as failures
`SwiftUI/NetworkResource.swift` and `SwiftUI/Paged.swift` both `catch is CancellationError { ... }`,
but `NetworkClient.request` normalizes cancellation to `NetworkError.cancelled` and never
rethrows `CancellationError`. The catch is dead code; a cancelled reload / page falls to the
generic catch and sets `phase = .failed(.cancelled)` / returns `.failure(.cancelled)`. Fast
typing in a search field flashes an error state. Use `catch let e as NetworkError where e.code == .cancelled`.

### 4e. PublisherBox `@unchecked Sendable` gap
`Combine/NetworkClient+Publishers.swift` locks `subject.send` but `var task` is written in
`receiveSubscription` and read/cancelled in `receiveCancel` with no synchronization. Put `task`
under the same lock.

---

## 5. Diagnosability (fix in 1.1 where non-breaking)

- `Security/ServerTrustEvaluator.swift`: the `CFError` from `SecTrustEvaluateWithError` is
  captured and dropped, and chain-evaluation failure vs no-pin-matched produce the identical
  `.sslPinningFailed(host:)`. A production pinning outage gives you a hostname and nothing else.
  Needs an `underlying` / reason slot on the error case (breaking, see section 6).
- `OAuth/AuthorizationCodeFlow.swift` `guard let token = try? decoder.decode(...) else { throw .malformedTokenResponse }`
  drops the `DecodingError` needed to fix a provider integration.
- `Core/NetworkClient+Pagination.swift`: hitting `maxPages` logs one line then finishes normally;
  `collectAll` returns a partial array that looks complete. Finish with a dedicated error or a
  "truncated" terminal value.
- `Upload/MultipartFormData.swift` `defer { try? handle.close() }`: for a streamed write,
  `close()` is where flush errors surface. Swallowing it hands a truncated body to the transport.
  Close inside the `do` and map to `.encoding`.
- `Transport/TransportSessionDelegate.swift` download: `try? FileManager.default.moveItem(...)`
  then `_fileURL` is set unconditionally. If the move fails the caller gets a URL to a file
  `URLSession` then deletes. Only set `_fileURL` on a successful move.
- `Core/NetworkClient+Upload.swift`: `upload` / `download` run request interceptors but never
  `interceptors.resolve` (response side). A `ResponseInterceptor` that would `.fail` or rewrite
  the body is silently bypassed for transfers; the doc comment says otherwise.

---

## 6. API-shape issues to weigh for a 2.0 (breaking)

The 1.0 API is frozen, so these need a major bump.

- **Non-throwing `NetworkClient.init` traps on recoverable conditions.**
  `preconditionFailure` when the default transport cannot resolve SSL pinning (loads a bundled
  resource, can fail in a downstream build), `precondition` on an empty enforced pin list,
  `preconditionFailure` on a malformed base-URL string (`NetworkConfiguration`). A throwing
  initializer or a validated factory would let apps handle these.
- **`asSendableError` always boxes; docs say `URLError` / `DecodingError` / `EncodingError` pass
  through untouched.** They do not. `NetworkError.decoding/.encoding/.transport(underlying:)`
  hand consumers an `any Error & Sendable` they cannot pattern-match. Also inconsistent:
  `.transport` carries a real `URLError` from `NetworkError.normalize` but a box from
  `NetworkTransport`. Decide whether the underlying is meant to be introspectable and make it
  consistent.
- **`NetworkError.sslPinningFailed(host:)` has no `underlying` slot** (see section 5).
- **`AuthorizationCodeFlow.authorizationURL` force-unwraps** `URLComponents(url:...)!` and
  `components.url!` on app-supplied config; should be `throws` or return `URL?`.
- `SSLPinningConfiguration.includeSubdomains` is not reachable through the public `SSLPinning`
  enum (always `false`).

---

## 7. Low / polish

- `SwiftUI/NetworkResource.swift` doc says `deinit` cancels the in-flight task; there is no
  `deinit`. Add `deinit { task?.cancel() }`.
- `TokenManager` doc says the session-expired callback fires once; it can fire on every failed
  `performRefresh` and again on the retry-twice path. Dedupe or fix the doc.
- `NetworkStatusBroadcaster` and `OfflineRequestQueue` `AsyncStream`s use default unbounded
  buffering; a slow or absent consumer grows memory. Consider `.bufferingNewest(n)`.
- `ServerTrustEvaluator.spkiSHA256` returns `nil` without CryptoKit (public-key pinning
  silently always-rejects on a Security-without-CryptoKit platform); the `SHA256Fallback` is not
  reused here. Near-dead path, but surprising asymmetry.
- `URLSessionTransport.init(session:)`: `upload` / `download` ignore the caller's session and
  spin fresh sessions from a copied config, dropping any delegate-based auth or pinning the
  caller configured. Doc callout.
- `RequestBuilder` / `RequestBody` / `AuthorizationCodeFlow` `value.addingPercentEncoding(...) ?? value`
  ships the raw value on `nil` (unpaired surrogates only). Given `encodePathParameter`'s
  injection-defence purpose, prefer throwing `.invalidURL` / `.encoding`.
- `DiskCacheStore` decode-failure returns `nil` and never removes the bad file; it fails forever
  and still counts toward eviction. `contentsOfDirectory` failing in `evictIfNeeded` gives
  `total = 0` so eviction never runs and the cache grows unbounded.
- `Core/NetworkClient.swift` `defer { Task { await registry.deregister(id) } }` is
  fire-and-forget; a dropped task leaks the registry entry.
- `StatusCodeMapper` allocates a `DateFormatter` per `Retry-After` parse.
- `RequestDeduplicator` type mismatch maps to `.unknown(underlying: nil)`, undiagnosable if it
  ever triggers.
- `InMemoryTokenStorage.init(seed:)` uses `try? JSONEncoder().encode(pair)`; an encode failure
  silently produces empty storage.
- `SSLPinning.swift`: a `.cer` resource that exists but fails to read throws
  `.resourceNotFound`, mislabeling a read/permission failure as missing.
- `RetryDecision`: the default policy retries `.noInternet` with full backoff before the offline
  queue / fast-fail can act.
- Offline replay uses the archived `Authorization` header with no refresh hop, and replays
  POST/PATCH with no idempotency guard (double-submit risk). Document the expectation; add a
  refresh hook.
- `KeychainTokenStorage`: no `kSecUseDataProtectionKeychain` (on macOS the legacy keychain
  ignores `kSecAttrAccessible`); the `errSecDuplicateItem` update path updates only the value,
  not the accessibility class.
