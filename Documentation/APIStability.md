# API Stability Audit (toward 1.0.0)

Input for the public API freeze. 101 public top-level types today. This proposes what to
**keep**, what to move **behind SPI**, and what to make **internal** before `1.0.0`, after
which every remaining public symbol is a semver commitment.

Method: the DocC symbol graph plus a reference scan (does any other public declaration name
the type?), then a manual pass for concrete types users construct by name.

## 1. Keep public (stable)

Everything a caller names to configure a client, describe an endpoint, or handle a result.

| Group | Types |
|---|---|
| Entry points | `NetworkClient`, `NetworkConfiguration`, `NetworkEnvironment`, `EnvironmentKind`, `Endpoint`, `AnyEndpoint`, `PaginatedEndpoint` |
| Request / response model | `HTTPMethod`, `HTTPHeaders`, `HTTPStatus`, `QueryParameters`, `QueryValue`, `RequestBody`, `RequestID`, `RequestPriority`, `ResponseContext`, `ProgressEvent`, `EmptyResponse`, `UploadBody`, `MultipartFormData` |
| Errors | `NetworkError`, `EndpointDecodingFailure`, `OAuthError`, `KeychainError`, `SSLPinningError` |
| Auth | `AuthStrategy`, `BearerAuth`, `BasicAuth`, `APIKeyAuth`, `CustomAuth`, `AuthRequirement`, `TokenStorage`, `TokenPair`, `TokenManager`, `KeychainTokenStorage`, `KeychainAccessibility`, `InMemoryTokenStorage` |
| OAuth | `AuthorizationCodeFlow`, `OAuthConfiguration`, `OAuthTokenResponse`, `PKCE` |
| Resilience | `RetryPolicy`, `BackoffStrategy`, `Jitter`, `NetworkClock`, `CachePolicy`, `CacheConfiguration`, `CachedResponse`, `ResponseCache`, `MemoryCacheStore`, `DiskCacheStore` |
| Offline | `OfflineBehavior`, `OfflineStore`, `OfflineReplayEvent`, `PersistedRequest`, `FileOfflineStore` |
| Transport / connectivity | `NetworkTransport`, `URLSessionTransport`, `NetworkMonitor`, `PathNetworkMonitor`, `NetworkStatus`, `ConnectionType` |
| Observability | `RequestInterceptor`, `ResponseInterceptor`, `InterceptOutcome`, `NetworkLogger`, `ConsoleNetworkLogger`, `LogLevel`, `Redactor`, `NetworkMetrics`, `InMemoryMetrics`, `NoopMetrics`, `MetricEvent`, `MetricsSnapshot`, `TraceHeaders`, `TracingInterceptor` |
| Security | `SSLPinning`, `SSLPinningConfiguration`, `PinningMode`, `Pin`, `ServerTrustEvaluating`, `ServerTrustDecision` |
| SwiftUI / Combine | `NetworkResource`, `Paged`, `DownloadState`, `UploadState` |
| Namespace | `SwiftNetworkKit` |

## 2. Move behind `@_spi(SwiftNetworkKitTesting)`

Shipped so consuming apps can use them, but not part of the stable surface. Test targets
import with `@_spi(SwiftNetworkKitTesting) import SwiftNetworkKit`.

| Type | Purpose |
|---|---|
| `MockNetworkTransport` | scriptable `NetworkTransport` |
| `URLProtocolStub` | `URLSession` stub at the `URLProtocol` layer |
| `MockNetworkMonitor` | push connectivity changes |
| `InMemoryOfflineStore` | no-disk `OfflineStore` |
| `TestClock` | deterministic `NetworkClock` |
| `CapturingLogger` | assertable `NetworkLogger` |
| `MockScenario` | preset transport scripts |

**Breaking change** for anyone already importing these; call it out in the `1.0.0` notes and
`CHANGELOG`.

## 3. Recommend making internal

Public today only because access control was not tightened. None appear in a public
signature and none are meant to be constructed by a caller.

| Type | Why internal | Risk |
|---|---|---|
| `SendableErrorBox` | error-boxing plumbing behind `any Error & Sendable` | none |
| `StatusCodeMapper` | maps a status code to a `NetworkError`; internal to the pipeline | none |
| `RetryDecision` | the retry loop's internal verdict | none |
| `ContinuousClockAdapter` | the default `NetworkClock`; callers use the protocol or `TestClock` | low, keep public if you want a nameable default |
| `OfflineRequestQueue` | the client owns it; callers use `client.offlineReplayEvents()` / `replayOfflineQueue()` | low, unless someone drives the queue directly |

`ServerTrustEvaluator` (the concrete evaluator) is borderline: wired automatically from
`sslPinning`, but an advanced user building a custom transport may want it. Suggest **keep
public**.

## 4. To decide

- **`@_spi` name**: `SwiftNetworkKitTesting` proposed.
- **`EndpointDecodingFailure`**: keep as a distinct catchable error, or fold into
  `NetworkError.decoding`?
- **`HTTPStatus`**: keep the convenience enum, or drop it (callers have raw `Int` +
  `NetworkError`)?
- **Nested / associated types**: audit `TokenManager.RefreshHandler`,
  `MockNetworkTransport.Outcome`, etc. for the same treatment.

## Execution (once approved)

1. Add `-enable-library-evolution`? No , a source package does not need it; skip.
2. `internal` the section-3 types, run the suite (tests use `@testable`, so no test breakage).
3. Add `@_spi(SwiftNetworkKitTesting)` to the section-2 types and their public members; add
   the import to `Tests/` and to `Sources/NetworkKitBenchmarks` / `SwiftUIDemo`.
4. Update `SwiftNetworkKit.docc/SwiftNetworkKit.md` Topics (drop the Testing group or mark it
   SPI), and `Documentation/APIReference.md` (regenerate).
5. `CHANGELOG` + release notes: list the SPI move as the one breaking change.
