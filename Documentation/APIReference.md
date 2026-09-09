# SwiftNetworkKit Public API Reference

Generated from the DocC symbol graph. 101 public types. Regenerate after any public-API change:

```bash
swift package dump-symbol-graph --minimum-access-level public
python3 scripts/gen-api-reference.py > Documentation/APIReference.md
```

| Area | Types |
|---|---|
| Core | `AuthRequirement`, `EmptyResponse`, `Endpoint`, `EndpointDecodingFailure`, `HTTPHeaders`, `HTTPMethod`, `HTTPStatus`, `NetworkCancellable`, `NetworkClient`, `NetworkConfiguration`, `NetworkError`, `ProgressEvent`, `QueryParameters`, `QueryValue`, `RequestBody`, `RequestID`, `RequestPriority`, `ResponseContext`, `SendableErrorBox`, `StatusCodeMapper` |
| Environment | `EnvironmentKind`, `NetworkEnvironment` |
| Authentication | `APIKeyAuth`, `AuthStrategy`, `BasicAuth`, `BearerAuth`, `CustomAuth`, `InMemoryTokenStorage`, `KeychainAccessibility`, `KeychainError`, `KeychainTokenStorage`, `TokenManager`, `TokenPair`, `TokenStorage` |
| OAuth 2.0 | `AuthorizationCodeFlow`, `OAuthConfiguration`, `OAuthError`, `OAuthTokenResponse`, `PKCE` |
| Resilience | `BackoffStrategy`, `ContinuousClockAdapter`, `Jitter`, `NetworkClock`, `RetryDecision`, `RetryPolicy` |
| Caching | `CacheConfiguration`, `CachePolicy`, `CachedResponse`, `DiskCacheStore`, `MemoryCacheStore`, `ResponseCache` |
| Offline queue | `FileOfflineStore`, `OfflineBehavior`, `OfflineReplayEvent`, `OfflineRequestQueue`, `OfflineStore`, `PersistedRequest` |
| Transport & connectivity | `ConnectionType`, `NetworkMonitor`, `NetworkStatus`, `NetworkTransport`, `PathNetworkMonitor`, `URLSessionTransport` |
| Interceptors & observability | `AnyEndpoint`, `ConsoleNetworkLogger`, `InMemoryMetrics`, `InterceptOutcome`, `LogLevel`, `MetricEvent`, `MetricsSnapshot`, `NetworkLogger`, `NetworkMetrics`, `NoopMetrics`, `Redactor`, `RequestInterceptor`, `ResponseInterceptor`, `TraceHeaders`, `TracingInterceptor` |
| Security & pinning | `Pin`, `PinningMode`, `SSLPinning`, `SSLPinningConfiguration`, `SSLPinningError`, `ServerTrustDecision`, `ServerTrustEvaluating`, `ServerTrustEvaluator` |
| Transfers | `MultipartFormData`, `UploadBody` |
| Pagination | `PaginatedEndpoint` |
| Combine & SwiftUI | `DownloadState`, `NetworkResource`, `Paged`, `UploadState` |
| Testing utilities | `CapturingLogger`, `InMemoryOfflineStore`, `MockNetworkMonitor`, `MockNetworkTransport`, `MockScenario`, `TestClock`, `URLProtocolStub` |
| Other | `SwiftNetworkKit` |

## Core

### `AuthRequirement`  `enum`

Whether, and how, a request needs authentication applied.

**Cases:** `.custom(_:)`, `.none`, `.required`

**Properties:** `isAuthenticated`

### `EmptyResponse`  `struct`

A response body that is expected to be empty (204, or a write with no useful payload).

### `Endpoint`  `protocol`

One API operation, defined by the consuming app.

### `EndpointDecodingFailure`  `enum`

Reasons the default ``Endpoint`` decoder cannot produce a value.

**Cases:** `.responseNotUTF8`, `.unsupportedResponseType(_:)`

**Properties:** `localizedDescription`

### `HTTPHeaders`  `struct`

A case-insensitive collection of HTTP header fields.

**Properties:** `count`, `dictionary`, `isEmpty`, `lazy`, `publisher`, `underestimatedCount`

**Methods:** `add(name:value:)()`, `allSatisfy(_:)()`, `compactMap(_:)()`, `compare(_:_:)()`, `contains(_:)()`, `contains(where:)()`, `count(where:)()`, `drop(while:)()`, `dropFirst(_:)()`, `dropLast(_:)()`, `elementsEqual(_:)()`, `elementsEqual(_:by:)()`, `encode(to:)()`, `enumerated()()` _(+26 more)_

### `HTTPMethod`  `enum`

An HTTP request method.

**Cases:** `.custom(_:)`, `.delete`, `.get`, `.head`, `.options`, `.patch`, `.post`, `.put`, `.trace`

**Properties:** `isCacheable`, `isIdempotent`, `rawValue`

### `HTTPStatus`  `enum`

Helpers for classifying HTTP status codes.

**Methods:** `isClientError(_:)()`, `isRedirect(_:)()`, `isServerError(_:)()`, `isSuccess(_:)()`

### `NetworkCancellable`  `struct`

A handle for cancelling an in-flight request started via a completion-handler call.

**Methods:** `cancel()()`

### `NetworkClient`  `class`

The public entry point.

**Properties:** `configuration`

**Methods:** `batch(_:)()`, `cancel(_:)()`, `cancelAll()()`, `collectAll(_:max:)()`, `data(for:)()`, `download(_:to:progress:)()`, `downloadPublisher(_:to:)()`, `offlineReplayEvents()()`, `paginate(_:maxPages:)()`, `paginatePublisher(_:)()`, `pauseQueue()()`, `publisher(for:)()`, `replayOfflineQueue()()`, `request(_:completion:)()` _(+9 more)_

### `NetworkConfiguration`  `struct`

Central configuration for a `NetworkClient`.

**Properties:** `authorization`, `cache`, `clock`, `defaultDecoder`, `defaultEncoder`, `defaultRedactedBodyKeys`, `defaultRedactedHeaders`, `enableDeduplication`, `environment`, `errorMapper`, `logger`, `maxConcurrentRequests`, `metrics`, `networkMonitor` _(+10 more)_

### `NetworkError`  `enum`

The single error type crossing SwiftNetworkKit's public boundary.

**Cases:** `.cancelled`, `.decoding(underlying:_:)`, `.encoding(underlying:)`, `.forbidden(_:)`, `.invalidURL(_:)`, `.noInternet`, `.notFound(_:)`, `.offline`, `.offlineQueued(_:)`, `.rateLimited(retryAfter:_:)`, `.server(_:)`, `.sessionExpired`, `.sslPinningFailed(host:)`, `.timeout`, `.tokenRefreshFailed(underlying:)`, `.transport(underlying:)`, `.unacceptableStatusCode(_:_:)`, `.unauthorized(_:)`, `.unknown(underlying:)`, `.validation(_:)`

**Properties:** `code`, `errorDescription`, `failureReason`, `helpAnchor`, `isRetryable`, `localizedDescription`, `recoverySuggestion`, `responseContext`, `responseData`, `responseHeaders`, `serverMessage`, `statusCode`

**Methods:** `normalize(_:)()`

### `ProgressEvent`  `struct`

A byte-count update for an in-flight upload or download.

**Properties:** `completed`, `fraction`, `total`

### `QueryParameters`  `struct`

An ordered set of URL query parameters.

**Properties:** `items`

**Methods:** `append(_:_:)()`, `percentEncodedQueryString()()`, `queryItems()()`

### `QueryValue`  `enum`

A typed value for a URL query parameter.

**Cases:** `.bool(_:)`, `.double(_:)`, `.int(_:)`, `.list(_:)`, `.string(_:)`

### `RequestBody`  `enum`

The payload of a request.

**Cases:** `.data(_:)`, `.formURLEncoded(_:)`, `.json(_:)`, `.multipart(_:)`

**Methods:** `encoded()()`, `json(_:encoder:)()`

### `RequestID`  `struct`

A process-unique identifier for one logical request (survives auth-refresh retries).

**Properties:** `description`, `rawValue`

### `RequestPriority`  `enum`

Relative scheduling hint for the request queue.

**Cases:** `.high`, `.low`, `.normal`

### `ResponseContext`  `struct`

Everything about a server response needed to diagnose a failure.

**Properties:** `data`, `headers`, `request`, `serverMessage`, `statusCode`

### `SendableErrorBox`  `struct`

A `Sendable` wrapper for an arbitrary error whose concrete type may not itself be `Sendable`.

**Properties:** `description`, `localizedDescription`, `underlyingType`

### `StatusCodeMapper`  `enum`

The one place HTTP status codes become ``NetworkError`` values.

**Methods:** `map(context:errorMapper:)()`


## Environment

### `EnvironmentKind`  `enum`

Which deployment an environment represents.

**Cases:** `.development`, `.production`, `.qa`, `.staging`

**Properties:** `hashValue`

**Methods:** `hash(into:)()`

### `NetworkEnvironment`  `struct`

A named set of connection settings.

**Properties:** `baseURL`, `defaultHeaders`, `kind`, `logLevel`, `timeout`

**Methods:** `development(baseURL:headers:timeout:)()`, `production(baseURL:headers:timeout:)()`, `qa(baseURL:headers:timeout:)()`, `staging(baseURL:headers:timeout:)()`


## Authentication

### `APIKeyAuth`  `struct`

A static API key, sent either as a header or as a query item.

**Properties:** `placement`, `value`

**Methods:** `authorize(_:token:)()`

### `AuthStrategy`  `protocol`

Applies authentication to an outgoing request.

### `BasicAuth`  `struct`

HTTP Basic authentication: `Authorization: Basic base64(username:password)`.

**Properties:** `password`, `username`

**Methods:** `authorize(_:token:)()`

### `BearerAuth`  `struct`

`Authorization: Bearer <token>`.

**Methods:** `authorize(_:token:)()`

### `CustomAuth`  `struct`

An arbitrary app-supplied authentication closure.

**Methods:** `authorize(_:token:)()`

### `InMemoryTokenStorage`  `class`

Non-persistent storage.

**Properties:** `tokenPairKey`

**Methods:** `accessToken()()`, `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `clearTokenPair()()`, `currentTokenPair()()`, `data(forKey:)()`, `preconditionIsolated(_:file:line:)()`, `refreshToken()()`, `removeAll()()`, `setData(_:forKey:)()`, `store(_:)()`, `withSerialExecutor(_:)()`

### `KeychainAccessibility`  `enum`

Keychain accessibility classes, wrapped so the storage type stays `Sendable` (the underlying `CFString` constants are not).

**Cases:** `.afterFirstUnlock`, `.afterFirstUnlockThisDeviceOnly`, `.whenUnlocked`, `.whenUnlockedThisDeviceOnly`

### `KeychainError`  `struct`

A keychain-backed OSStatus failure.

**Properties:** `description`, `localizedDescription`, `status`

### `KeychainTokenStorage`  `struct`

`TokenStorage` backed by the system keychain (generic-password items keyed by `service` + account).

**Properties:** `accessGroup`, `accessibility`, `isAvailable`, `service`, `tokenPairKey`

**Methods:** `accessToken()()`, `clearTokenPair()()`, `currentTokenPair()()`, `data(forKey:)()`, `refreshToken()()`, `removeAll()()`, `setData(_:forKey:)()`, `store(_:)()`

### `TokenManager`  `class`

Coordinates access-token refresh so that: , concurrent 401s trigger **exactly one** refresh network call (single-flight), callers that arrive during a refresh **queue** on the same operation, a given original request is only retried once, a second 401 for it means the session is 

**Methods:** `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `expireSession()()`, `preconditionIsolated(_:file:line:)()`, `refreshedToken(forRetryOf:)()`, `tokenForOutgoingRequest()()`, `withSerialExecutor(_:)()`

### `TokenPair`  `struct`

An access/refresh token pair with an optional expiry.

**Properties:** `accessToken`, `expiresAt`, `refreshToken`

**Methods:** `isExpired(leeway:)()`

### `TokenStorage`  `protocol`

Pluggable secure storage for tokens and related secrets.

**Properties:** `tokenPairKey`

**Methods:** `accessToken()()`, `clearTokenPair()()`, `currentTokenPair()()`, `refreshToken()()`, `store(_:)()`


## OAuth 2.0

### `AuthorizationCodeFlow`  `struct`

The OAuth 2.0 Authorization Code flow with PKCE, URL building and token exchange.

**Properties:** `configuration`

**Methods:** `authorizationCode(fromRedirect:expectedState:)()`, `authorizationURL(state:pkce:)()`, `exchange(code:pkce:)()`, `makeState()()`, `refresh(refreshToken:)()`, `tokenManagerRefreshHandler()()`

### `OAuthConfiguration`  `struct`

Everything ``AuthorizationCodeFlow`` needs to talk to an OAuth 2.0 provider.

**Properties:** `additionalAuthParameters`, `authorizationEndpoint`, `clientID`, `clientSecret`, `redirectURI`, `scopes`, `tokenEndpoint`

### `OAuthError`  `enum`

Why an OAuth step failed.

**Cases:** `.authorizationDenied(_:)`, `.malformedTokenResponse`, `.missingAuthorizationCode`, `.stateMismatch`, `.tokenRequestFailed(status:body:)`

**Properties:** `localizedDescription`

### `OAuthTokenResponse`  `struct`

A successful OAuth 2.0 token response (RFC 6749 §5.1).

**Properties:** `accessToken`, `expiresIn`, `expiryDate`, `receivedAt`, `refreshToken`, `scope`, `tokenType`

### `PKCE`  `struct`

A PKCE (RFC 7636) verifier/challenge pair.

**Properties:** `challenge`, `method`, `verifier`


## Resilience

### `BackoffStrategy`  `enum`

Computes how long to wait before the next retry attempt.

**Cases:** `.constant(_:)`, `.exponential(base:multiplier:maxDelay:)`

**Methods:** `delay(forAttempt:jitter:)()`

### `ContinuousClockAdapter`  `struct`

The production ``NetworkClock``: a thin wrapper over `ContinuousClock` and `Task.sleep`.

**Methods:** `now()()`, `sleep(for:)()`

### `Jitter`  `enum`

How much randomness to fold into a computed backoff delay, so a fleet of clients that all failed at the same moment don't retry in lockstep.

**Cases:** `.equal`, `.full`, `.none`

**Methods:** `apply(to:)()`

### `NetworkClock`  `protocol`

The time port.

### `RetryDecision`  `enum`

The outcome of asking "should this failed attempt be retried, and after how long?".

**Cases:** `.retry(after:)`, `.stop`

### `RetryPolicy`  `struct`

Value-typed retry configuration.

**Properties:** `aggressive`, `backoff`, `default`, `jitter`, `maxAttempts`, `maxRetryAfterDelay`, `none`, `respectRetryAfter`, `retryNonIdempotent`, `retryableStatusCodes`, `retryableURLErrorCodes`


## Caching

### `CacheConfiguration`  `struct`

Response-caching settings on ``NetworkConfiguration``.

**Properties:** `defaultPolicy`, `defaultTTL`, `disabled`, `store`

**Methods:** `memory(policy:limitBytes:defaultTTL:)()`

### `CachePolicy`  `enum`

How a request interacts with the ``ResponseCache``.

**Cases:** `.cacheFirst`, `.cacheOnly`, `.ignoreCache`, `.networkFirst`, `.networkOnly`, `.staleWhileRevalidate`

### `CachedResponse`  `struct`

A stored HTTP response.

**Properties:** `data`, `etag`, `headers`, `maxAge`, `statusCode`, `storedAt`

**Methods:** `isFresh(ttl:now:)()`

### `DiskCacheStore`  `class`

A ``ResponseCache`` that persists entries as JSON files in a directory, with LRU eviction by total size.

**Methods:** `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `preconditionIsolated(_:file:line:)()`, `remove(forKey:)()`, `removeAll()()`, `setValue(_:forKey:)()`, `value(forKey:)()`, `withSerialExecutor(_:)()`

### `MemoryCacheStore`  `class`

An in-memory ``ResponseCache`` with LRU eviction once the total stored size passes `limitBytes`.

**Properties:** `count`

**Methods:** `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `preconditionIsolated(_:file:line:)()`, `remove(forKey:)()`, `removeAll()()`, `setValue(_:forKey:)()`, `value(forKey:)()`, `withSerialExecutor(_:)()`

### `ResponseCache`  `protocol`

A key/value store of ``CachedResponse`` values.


## Offline queue

### `FileOfflineStore`  `class`

An ``OfflineStore`` backed by a single JSON file.

**Methods:** `all()()`, `append(_:)()`, `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `preconditionIsolated(_:file:line:)()`, `remove(_:)()`, `removeAll()()`, `update(_:)()`, `withSerialExecutor(_:)()`

### `OfflineBehavior`  `enum`

What an ``Endpoint`` does when it's sent while the device is offline.

**Cases:** `.fail`, `.queue(expiresAfter:)`

### `OfflineReplayEvent`  `enum`

What happened to a queued request when connectivity returned.

**Cases:** `.expired(_:)`, `.failed(_:_:)`, `.replayed(_:statusCode:)`

### `OfflineRequestQueue`  `class`

Persists requests made while offline and replays them FIFO when connectivity returns.

**Properties:** `pendingCount`

**Methods:** `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `enqueue(_:expiresAfter:)()`, `events()()`, `preconditionIsolated(_:file:line:)()`, `replayNow()()`, `withSerialExecutor(_:)()`

### `OfflineStore`  `protocol`

Persistence for the offline request queue.

### `PersistedRequest`  `struct`

A request captured while offline, waiting to be replayed.

**Properties:** `attempts`, `createdAt`, `expiresAt`, `id`, `urlRequestData`


## Transport & connectivity

### `ConnectionType`  `enum`

The kind of link a satisfied network path is using.

**Cases:** `.cellular`, `.other`, `.wifi`, `.wiredEthernet`

### `NetworkMonitor`  `protocol`

Connectivity state plus a live stream of changes.

**Methods:** `connectionRestored()()`

### `NetworkStatus`  `enum`

A snapshot of connectivity, mirroring `NWPath.Status`.

**Cases:** `.requiresConnection`, `.satisfied(_:)`, `.unsatisfied`

**Properties:** `connectionType`, `isOnline`

### `NetworkTransport`  `protocol`

The lowest layer: turns a fully-formed `URLRequest` into response bytes.

### `PathNetworkMonitor`  `class`

The default ``NetworkMonitor``: one `NWPathMonitor` on a dedicated queue, fanned out to subscribers.

**Properties:** `currentStatus`

**Methods:** `connectionRestored()()`, `statusUpdates()()`

### `URLSessionTransport`  `class`

The default ``NetworkTransport``, backed by `URLSession`.

**Methods:** `data(for:)()`, `download(_:progress:)()`, `upload(_:from:progress:)()`


## Interceptors & observability

### `AnyEndpoint`  `struct`

A type-erased ``Endpoint``: the metadata an interceptor, logger or registry needs, plus a `@Sendable` decode thunk, without the `associatedtype Response` that blocks heterogeneous storage.

**Properties:** `authentication`, `baseURL`, `headers`, `method`, `path`, `priority`

**Methods:** `decode(_:response:using:)()`

### `ConsoleNetworkLogger`  `struct`

The default ``NetworkLogger``.

**Methods:** `log(_:level:)()`

### `InMemoryMetrics`  `class`

A ``NetworkMetrics`` that aggregates events in memory.

**Methods:** `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `preconditionIsolated(_:file:line:)()`, `record(_:)()`, `reset()()`, `snapshot()()`, `withSerialExecutor(_:)()`

### `InterceptOutcome`  `enum`

What a ``ResponseInterceptor`` wants the pipeline to do with a response.

**Cases:** `.fail(_:)`, `.proceed`, `.retry(after:)`, `.substitute(_:)`

### `LogLevel`  `enum`

Verbosity of network logging.

**Cases:** `.basic`, `.debug`, `.error`, `.none`, `.verbose`

**Properties:** `hashValue`

**Methods:** `hash(into:)()`

### `MetricEvent`  `enum`

A single observable moment in a request's life.

**Cases:** `.failure(_:_:status:)`, `.requestStarted(_:)`, `.retry(_:attempt:)`, `.success(_:duration:status:)`, `.timeout(_:)`, `.tokenRefresh(success:)`

### `MetricsSnapshot`  `struct`

An immutable readout of everything ``InMemoryMetrics`` has aggregated so far.

**Properties:** `averageDuration`, `empty`, `failureCount`, `p95Duration`, `requestCount`, `retryCount`, `statusCodeHistogram`, `successCount`, `timeoutCount`, `tokenRefreshCount`, `tokenRefreshSuccessCount`

### `NetworkLogger`  `protocol`

The logging sink: receives fully-formatted, already-redacted lines.

### `NetworkMetrics`  `protocol`

Observability hook.

### `NoopMetrics`  `struct`

The default ``NetworkMetrics``: discards every event.

**Methods:** `record(_:)()`

### `Redactor`  `struct`

Pure, testable redaction of sensitive header values and JSON body keys.

**Properties:** `alwaysRedactedHeaders`, `placeholder`

**Methods:** `redact(body:)()`, `redact(headers:)()`

### `RequestInterceptor`  `protocol`

Adapts an outgoing `URLRequest` just before it is sent.

### `ResponseInterceptor`  `protocol`

Inspects a response before status mapping and decoding.

### `TraceHeaders`  `struct`

Which correlation headers ``TracingInterceptor`` attaches, and under what names.

**Properties:** `correlationIDHeader`, `disabled`, `emitW3CTraceparent`, `requestIDHeader`

### `TracingInterceptor`  `struct`

Attaches correlation headers to every outgoing request per ``TraceHeaders``.

**Properties:** `headers`

**Methods:** `adapt(_:for:)()`


## Security & pinning

### `Pin`  `enum`

One thing a server's certificate chain can be checked against.

**Cases:** `.certificate(_:)`, `.publicKeySHA256(_:)`

### `PinningMode`  `enum`

Whether a failed pin check blocks the connection.

**Cases:** `.enforced`, `.recordOnly`

### `SSLPinning`  `enum`

The one line an app writes to enable pinning.

**Cases:** `.certificateResources(_:extension:bundle:hosts:)`, `.certificates(_:hosts:)`, `.development(_:)`, `.disabled`, `.publicKeys(_:hosts:)`

**Methods:** `resolve(defaultHost:)()`

### `SSLPinningConfiguration`  `struct`

The resolved, immutable pinning rules a ``ServerTrustEvaluator`` works from.

**Properties:** `includeSubdomains`, `mode`, `pins`, `validateCertificateChain`

### `SSLPinningError`  `enum`

Why a ``SSLPinning`` value could not be resolved into pins.

**Cases:** `.invalidCertificate(source:)`, `.invalidPublicKeyHash(_:)`, `.noHostForPins`, `.resourceNotFound(name:extension:bundle:)`

**Properties:** `localizedDescription`

### `ServerTrustDecision`  `enum`

The outcome of evaluating one server-trust challenge against the resolved pinning rules.

**Cases:** `.notPinned`, `.pinned`, `.rejected(_:)`

### `ServerTrustEvaluating`  `protocol`

The port the transport's `URLSession` delegate calls for every server-trust challenge.

### `ServerTrustEvaluator`  `struct`

Validates a server's certificate chain against a resolved ``SSLPinningConfiguration``.

**Methods:** `evaluate(trust:host:)()`


## Transfers

### `MultipartFormData`  `struct`

Builds an RFC 7578 `multipart/form-data` body.

**Properties:** `boundary`, `contentType`

**Methods:** `append(_:name:)()`, `append(_:name:fileName:mimeType:)()`, `encoded()()`, `writeEncoded(to:)()`

### `UploadBody`  `enum`

What to send as an upload's request body.

**Cases:** `.data(_:)`, `.file(_:)`, `.multipart(_:)`


## Pagination

### `PaginatedEndpoint`  `protocol`

An ``Endpoint`` that returns one page of a larger collection.


## Combine & SwiftUI

### `DownloadState`  `enum`

What a download publisher emits: progress updates, then the local file URL.

**Cases:** `.finished(_:)`, `.progress(_:)`

### `NetworkResource`  `class`

An observable load-state holder for one endpoint's response.

**Properties:** `error`, `isLoading`, `phase`, `value`

**Methods:** `load(_:)()`, `reload()()`

### `Paged`  `class`

An observable, append-as-you-scroll list driven by a ``PaginatedEndpoint``.

**Properties:** `canLoadMore`, `error`, `isLoadingMore`, `items`

**Methods:** `loadMoreIfNeeded(currentItem:)()`, `start(_:)()`

### `UploadState`  `enum`

What an upload publisher emits: progress updates, then the decoded response.

**Cases:** `.finished(_:)`, `.progress(_:)`


## Testing utilities

### `CapturingLogger`  `class`

A ``NetworkLogger`` that keeps every line in memory for assertions.

**Properties:** `entries`, `lines`

**Methods:** `clear()()`, `log(_:level:)()`

### `InMemoryOfflineStore`  `class`

An ``OfflineStore`` that keeps the queue in memory.

**Properties:** `count`

**Methods:** `all()()`, `append(_:)()`, `assertIsolated(_:file:line:)()`, `assumeIsolated(_:file:line:)()`, `preconditionIsolated(_:file:line:)()`, `remove(_:)()`, `removeAll()()`, `update(_:)()`, `withSerialExecutor(_:)()`

### `MockNetworkMonitor`  `class`

A ``NetworkMonitor`` whose status you drive by hand.

**Properties:** `currentStatus`, `subscriberCount`

**Methods:** `connectionRestored()()`, `finish()()`, `send(_:)()`, `statusUpdates()()`

### `MockNetworkTransport`  `class`

An in-memory ``NetworkTransport`` for unit tests.

**Properties:** `recordedRequests`, `requestCount`

**Methods:** `data(for:)()`, `download(_:progress:)()`, `enqueue(_:)()`, `enqueueJSON(_:status:)()`, `stub(matching:with:)()`, `stub(method:pathContains:with:)()`, `upload(_:from:progress:)()`

### `MockScenario`  `enum`

Common server behaviors for ``MockNetworkTransport``, as a one-liner.

**Cases:** `.happyPath(body:)`, `.offline`, `.rateLimited`, `.serverErrors`, `.tokenExpired(body:)`

**Methods:** `transport(then:)()`

### `TestClock`  `class`

A ``NetworkClock`` for tests.

**Properties:** `recordedSleeps`, `virtualElapsed`

**Methods:** `now()()`, `sleep(for:)()`

### `URLProtocolStub`  `class`

A `URLProtocol` that intercepts every request so tests can exercise a *real* `URLSession` (and thus ``URLSessionTransport``) without touching the network.

**Properties:** `lastRequest`

**Methods:** `canInit(with:)()`, `canonicalRequest(for:)()`, `fail(with:)()`, `reset()()`, `respond(status:headers:body:)()`, `startLoading()()`, `stopLoading()()`


## Other

### `SwiftNetworkKit`  `enum`

SwiftNetworkKit, a composable, protocol-oriented networking layer.

**Properties:** `version`


