# SwiftNetworkKit

A composable, protocol-oriented networking layer for Swift. Zero external dependencies.
Swift 6 strict concurrency. iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+.

> **Status:** in development. Milestones M0 through M4 are complete (core types, request pipeline,
> authentication + automatic token refresh, retry + backoff + rate limiting, interceptors + tracing
> + redacting logger + metrics). See
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

## Demos

**CLI tour**: a scripted run through every shipped feature:

```bash
swift run NetworkKitDemo            # hits the live jsonplaceholder.typicode.com API
swift run NetworkKitDemo --offline  # auth + refresh section only, no network
```

Source: [`Sources/NetworkKitDemo/`](Sources/NetworkKitDemo/).

**SwiftUI app**: a complete standalone iOS app (MVVM + Clean Architecture) in
[`Examples/SwiftUIDemo/`](Examples/SwiftUIDemo/): searchable user list to detail, a POST form, and a
Diagnostics screen (client config + a narrated 401 to refresh to retry walkthrough).

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
| Request mocking (`MockNetworkTransport`, `URLProtocolStub`, `TestClock`, `CapturingLogger`) |

Not yet: SSL pinning, caching, upload/download, reachability, OAuth, offline queue, pagination,
batch, Combine/SwiftUI helpers. See the roadmap for the milestone order.

## Tests

```bash
swift test
swift test --sanitize=thread
```

## License

Apache-2.0.
