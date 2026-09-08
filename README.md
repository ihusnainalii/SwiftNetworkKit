# SwiftNetworkKit

A composable, protocol-oriented networking layer for Swift. Zero external dependencies.
Swift 6 strict concurrency. iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+.

> **Status:** in development. Milestones M0 through M12 are complete (core types, request pipeline,
> authentication + automatic token refresh, retry + backoff + rate limiting, interceptors + tracing
> + redacting logger + metrics, optional SSL / certificate pinning, reachability, multipart uploads
> and downloads with progress, HTTP response caching, request cancellation / deduplication /
> concurrency queue, OAuth 2.0 + PKCE, offline request queue, pagination + batch). See
> [`.claude/PRPs/plans/swift-network-kit.plan.md`](.claude/PRPs/plans/swift-network-kit.plan.md)
> for the full roadmap.

## Quick start

```swift
import SwiftNetworkKit

// 1. Configure once
let client = NetworkClient(
    configuration: NetworkConfiguration(
        baseURL: "https://api.example.com",
        headers: ["Accept": "application/json"],
        tokenStorage: KeychainTokenStorage(service: "com.acme.app")
    ),
    refresh: { storage in
        try await exchangeRefreshToken(storage.refreshToken())   // your call
    },
    onSessionExpired: { await AppRouter.logout() }
)

// 2. Declare an endpoint per API operation
struct GetProfile: Endpoint {
    typealias Response = User
    var path: String { "/me" }
    var authentication: AuthRequirement { .required }
}

// 3. Call it (three styles)
let user: User = try await client.request(GetProfile())               // async/await
client.request(GetProfile()) { (r: Result<User, NetworkError>) in }   // completion handler
```

A `.required` endpoint that 401s triggers a single-flight token refresh and one automatic retry;
a second 401 for the same request surfaces `NetworkError.sessionExpired`.

Transient failures (`5xx`, `408`, connectivity drops) are retried with exponential backoff and
jitter, capped by `RetryPolicy` (`maxAttempts` 3 by default). `POST` and `PATCH` are never retried
unless an endpoint opts in. `429` and `503` honor a server `Retry-After` header.

```swift
var configuration = NetworkConfiguration(baseURL: "https://api.example.com")
configuration.retry = .aggressive            // or .none, or a custom RetryPolicy

struct SubmitOrder: Endpoint {
    typealias Response = Order
    var method: HTTPMethod { .post }
    var retryPolicy: RetryPolicy? { RetryPolicy(retryNonIdempotent: true) }   // this POST is safe to repeat
}
```

### Interceptors, logging, metrics

```swift
let metrics = InMemoryMetrics()
var configuration = NetworkConfiguration(baseURL: "https://api.example.com")
configuration.environment.logLevel = .verbose      // redacted headers in the log; tokens never appear
configuration.metrics = metrics
configuration.requestInterceptors = [MyHeaderInterceptor()]     // adapt every outgoing request
configuration.responseInterceptors = [My2FAChallengeInterceptor()]   // proceed / retry / fail / substitute

let snapshot = await metrics.snapshot()   // requestCount, successCount, statusCodeHistogram, p95Duration, ...
```

Every request gets a unique `X-Request-ID`. Wrap a group of calls in
`client.withCorrelation(id) { ... }` to give them all one `X-Correlation-ID`.

### SSL / certificate pinning (optional)

The app ships its `.cer` files and writes one line. The package owns the `URLSession` delegate,
challenge handling and trust evaluation.

```swift
var config = NetworkConfiguration(baseURL: "https://api.acme.com")

config.sslPinning = .certificateResources(["acme-2025", "acme-2026"])   // .cer/.der in the app bundle
// or pin the key, which survives certificate renewal:
config.sslPinning = .publicKeys(["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="])
// or discover the values first (never blocks; logs the sha256/... to paste above):
config.sslPinning = .development(.publicKeys([]))
```

Omit it (or `.disabled`) for normal system TLS. A mismatch fails the request with
`NetworkError.sslPinningFailed(host:)`; a missing resource or bad hash fails `NetworkClient` init.

### Reachability

```swift
let monitor = PathNetworkMonitor()

for await status in await monitor.statusUpdates() {
    // .satisfied(.wifi) / .satisfied(.cellular) / .unsatisfied / .requiresConnection
}

for await _ in await monitor.connectionRestored() {
    // fires each time connectivity returns after a drop
}
```

Inject `MockNetworkMonitor` in tests and call `send(.unsatisfied)` / `send(.satisfied(.wifi))`.

### Uploads and downloads

```swift
var form = MultipartFormData()
form.append("a cat", name: "caption")
form.append(jpegData, name: "photo", fileName: "cat.jpg", mimeType: "image/jpeg")
// or a large file, streamed from disk: form.append(fileURL, name: "video")

let created: Photo = try await client.upload(CreatePhoto(), from: .multipart(form)) { event in
    print(event.fraction ?? 0)   // 0.0 ... 1.0
}

let fileURL = try await client.download(GetExport(), to: destinationURL) { event in
    print("\(event.completed) / \(event.total)")
}
```

Uploads are not retried and skip the 401-refresh hop (a partial upload is unsafe to replay).

### HTTP caching

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.cache = .memory(policy: .cacheFirst)          // or a custom CacheConfiguration
// disk-backed, survives launches:
config.cache = CacheConfiguration(store: DiskCacheStore(), defaultPolicy: .staleWhileRevalidate)

struct GetFeed: Endpoint {
    typealias Response = Feed
    var cachePolicy: CachePolicy? { .staleWhileRevalidate }   // per-endpoint override
}
```

Only `GET` / `HEAD` are cached. `ETag` responses are revalidated with `If-None-Match` (a `304`
reuses the stored body); `Cache-Control: no-store` is never persisted; `networkFirst` / `cacheFirst`
fall back to a cached response when the network fails.

### Cancellation, deduplication, concurrency

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.maxConcurrentRequests = 4          // extra requests queue, ordered by Endpoint.priority
config.enableDeduplication = true         // concurrent identical GETs share one in-flight call

let id = RequestID()
async let profile = client.request(GetProfile(), id: id)
// ...later, from anywhere:
await client.cancel(id)                   // or client.cancelAll()

await client.pauseQueue()                 // hold the queue (e.g. while offline)
await client.resumeQueue()
```

Cancelling the calling task also cancels the request. A token-refresh endpoint should set
`var skipRequestQueue: Bool { true }` so a full queue plus an expired token can't deadlock.

### OAuth 2.0 (Authorization Code + PKCE)

URL building and token exchange only. The app presents the URL (in `ASWebAuthenticationSession`) and
captures the redirect.

```swift
let flow = AuthorizationCodeFlow(configuration: OAuthConfiguration(
    authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
    tokenEndpoint: URL(string: "https://oauth2.googleapis.com/token")!,
    clientID: "…", redirectURI: "myapp://callback", scopes: ["openid", "profile"]
))

let state = AuthorizationCodeFlow.makeState()
let pkce = PKCE()
// present flow.authorizationURL(state: state, pkce: pkce), receive `redirectURL`
let code = try flow.authorizationCode(fromRedirect: redirectURL, expectedState: state)
let tokens = try await flow.exchange(code: code, pkce: pkce)

// hand automatic refresh to the client:
let client = NetworkClient(configuration: config, refresh: flow.tokenManagerRefreshHandler())
```

### Offline request queue

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.offlineStore = FileOfflineStore()          // persisted; survives launches
config.networkMonitor = PathNetworkMonitor()

struct SubmitOrder: Endpoint {
    typealias Response = Order
    var method: HTTPMethod { .post }
    var offlineBehavior: OfflineBehavior { .queue(expiresAfter: 3600) }
}
```

Sent offline, the request is archived and the caller gets `NetworkError.offlineQueued(id)`
immediately. When connectivity returns the queue replays FIFO; observe the outcomes:

```swift
for await event in await client.offlineReplayEvents() {
    // .replayed(id, statusCode:) / .failed(id, error) / .expired(id)
}
```

Multipart bodies can't be archived, so a multipart endpoint always fails fast instead.

### Pagination and batch

```swift
struct ListUsers: PaginatedEndpoint {
    typealias Response = [User]
    var page = 1
    var path: String { "/users" }
    var queryParameters: QueryParameters? { ["_page": .int(page), "_limit": .int(20)] }
    func items(from response: [User]) -> [User] { response }
    func nextPage(after response: [User]) -> Self? {
        response.isEmpty ? nil : { var next = self; next.page += 1; return next }()
    }
}

for try await pageOfUsers in client.paginate(ListUsers()) { ... }   // one array per page
let all = try await client.collectAll(ListUsers(), max: 200)        // flattened, capped

// parallel:
let (profile, feed) = try await client.zip(GetProfile(), GetFeed())
let results = await client.batch(ids.map { GetItem(id: $0) })       // [Result<Item, NetworkError>]
```

`paginate` honors task cancellation and caps at `maxPages` (default 1000) against a runaway server.
The endpoint owns the scheme entirely via `nextPage(after:)` (page number, cursor, `Link:` header).

## Demos

**CLI tour**: a scripted run through every shipped feature:

```bash
swift run NetworkKitDemo            # hits the live jsonplaceholder.typicode.com API
swift run NetworkKitDemo --offline  # auth + refresh section only, no network
```

Source: [`Sources/NetworkKitDemo/`](Sources/NetworkKitDemo/).

**SwiftUI app**: a complete standalone iOS app (MVVM + Clean Architecture) in
[`Examples/SwiftUIDemo/`](Examples/SwiftUIDemo/): searchable user list to detail, a POST form, an
image downloader with a live progress bar, and a Diagnostics screen (client config, connectivity,
metrics, and a narrated 401 to refresh to retry walkthrough).

Open `Examples/SwiftUIDemo/SwiftUIDemo.xcodeproj` in Xcode and run, or:

```bash
xcodebuild -project Examples/SwiftUIDemo/SwiftUIDemo.xcodeproj \
  -scheme SwiftUIDemo -destination 'generic/platform=iOS Simulator' build
```

## What's implemented

| Area |
|---|
| Generic HTTP (methods, headers, query, path params, JSON/form/raw bodies) |
| `Endpoint` abstraction with per-endpoint overrides |
| Typed decoding (`Decodable` / `Data` / `String` / `EmptyResponse`) |
| `async/await` + completion-handler APIs |
| Unified `NetworkError` (status, headers, body, server message) |
| Auth strategies (Bearer / API key / Basic / custom) |
| `TokenStorage` (in-memory + Keychain, pluggable) |
| Actor `TokenManager` (single-flight 401 refresh, queueing, loop guard) |
| Retry + backoff + jitter, idempotency-aware, `Retry-After` rate limiting |
| Request / response interceptors (`InterceptOutcome`: proceed / retry / fail / substitute) |
| Correlation headers (`X-Request-ID` per request, `withCorrelation` for a logical operation) |
| Redacting logger (`LogLevel` none / error / basic / verbose / debug; tokens never logged) |
| Metrics (`NetworkMetrics` sink, `InMemoryMetrics` -> counts, histogram, average / p95) |
| Optional SSL / certificate pinning (`.certificates` / `.publicKeys` / per-host / rotation / record-only) |
| Reachability (`NetworkMonitor` over `NWPathMonitor`, `AsyncStream` of status, `connectionRestored()`) |
| Multipart form data (`MultipartFormData`, RFC 7578, streams large file parts from disk) |
| Uploads and downloads with byte progress (`client.upload` / `client.download`) |
| HTTP response caching (`CachePolicy`, memory + disk stores, ETag / 304, stale-while-revalidate) |
| Request management: cancel by id / `cancelAll`, GET dedup, concurrency limit + priority, pause / resume |
| OAuth 2.0 Authorization Code + PKCE (`PKCE`, `AuthorizationCodeFlow`, auto-refresh adapter) |
| Offline request queue (opt-in per endpoint, persisted, replays FIFO on reconnect) |
| Pagination as an `AsyncSequence` (`client.paginate` / `collectAll`) + parallel `zip` / `batch` |
| Request mocking (`MockNetworkTransport`, `URLProtocolStub`, `TestClock`, `CapturingLogger`, `MockNetworkMonitor`, `InMemoryOfflineStore`) |

Not yet: Combine / SwiftUI helpers. See the roadmap for the milestone order.

## Tests

```bash
swift test
swift test --sanitize=thread
```

## License

Apache-2.0.
