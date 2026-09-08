# Changelog

All notable changes to SwiftNetworkKit are documented here. The format is based on
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/); this project has not yet cut a `1.0.0`
release, so everything below is under `[Unreleased]`.

## [Unreleased]

### Added

- **Core** (M0–M1): `NetworkClient`, `NetworkConfiguration`, `NetworkEnvironment`, `Endpoint`
  protocol with per-endpoint overrides, unified `NetworkError` (status / headers / body / server
  message), `HTTPMethod` / `HTTPHeaders` / `QueryParameters` / `HTTPStatus`, `RequestBuilder`,
  typed decoding (`Decodable` / `Data` / `String` / `EmptyResponse`), `async/await` +
  completion-handler APIs, `data` / `string` / `send` helpers.
- **Authentication** (M2): `AuthStrategy` (Bearer / API key / Basic / custom), `TokenStorage`
  (`InMemoryTokenStorage`, `KeychainTokenStorage`), actor `TokenManager` (single-flight 401
  refresh, request queueing, loop guard, proactive refresh).
- **Retry** (M3): `RetryPolicy` (`.default` / `.none` / `.aggressive`), `BackoffStrategy`
  (constant / exponential), `Jitter`, idempotency-aware `RetryDecision`, `NetworkClock` port +
  `TestClock`, `429` / `503` `Retry-After` handling.
- **Observability** (M4): request / response interceptors (`InterceptOutcome`), `TracingInterceptor`
  (`X-Request-ID`, `withCorrelation`), redacting `NetworkLogger` (`LogLevel`, `Redactor`),
  `NetworkMetrics` (`InMemoryMetrics` → counts / histogram / p95).
- **Security** (M5): optional `SSLPinning` (`.certificates` / `.certificateResources` /
  `.publicKeys` / `.development`), per-host, rotation-safe, record-only mode; app ships only the
  `.cer` files.
- **Connectivity** (M6): `NetworkMonitor` over `NWPathMonitor`, `AsyncStream` of `NetworkStatus`,
  `connectionRestored()`.
- **Transfer** (M7): `MultipartFormData` (RFC 7578, streams large file parts), `client.upload` /
  `client.download` with byte `ProgressEvent`.
- **Caching** (M8): `CachePolicy`, `MemoryCacheStore` / `DiskCacheStore`, ETag / `304`
  revalidation, stale-while-revalidate, network-failure fallback.
- **Request management** (M9): cancel by id / `cancelAll`, GET/HEAD deduplication, concurrency
  limit + priority queue, `pauseQueue` / `resumeQueue`.
- **OAuth** (M10): `PKCE`, `AuthorizationCodeFlow` (URL building + token exchange), auto-refresh
  adapter (`flow.tokenManagerRefreshHandler()`).
- **Offline** (M11): opt-in `OfflineBehavior.queue`, persisted `FileOfflineStore`, FIFO replay on
  reconnect, `offlineReplayEvents()`.
- **Pagination & batch** (M12): `PaginatedEndpoint`, `client.paginate` (`AsyncThrowingStream`) /
  `collectAll`, `client.zip` / `client.batch`.
- **Testing** (shipped in the library): `MockNetworkTransport` (FIFO queue, path/method matchers,
  `MockScenario` presets), `URLProtocolStub`, `TestClock`, `CapturingLogger`, `MockNetworkMonitor`,
  `InMemoryOfflineStore`.
- CI workflow (`swift build -warnings-as-errors`, `swift test`, ThreadSanitizer, iOS builds).

### Notes

- Every milestone has an implementation report under `.claude/PRPs/reports/`.
