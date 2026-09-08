# Roadmap

## Status

All fifteen build milestones are complete and on `main`. The package is feature-complete for a
`0.1.0` pre-release; the remaining work before `1.0.0` is API review, docs polish, and soak time.

Full milestone history and per-task detail: [`.claude/PRPs/plans/swift-network-kit.plan.md`](.claude/PRPs/plans/swift-network-kit.plan.md).
Per-milestone implementation reports: [`.claude/PRPs/reports/`](.claude/PRPs/reports/).

## Milestones (delivered, in build order)

| # | Milestone | Ships | Report |
|---|---|---|---|
| M0 | Package scaffold + core types | `NetworkClient`, `NetworkConfiguration`, `Endpoint`, `NetworkError`, HTTP value types | [M0](.claude/PRPs/reports/swift-network-kit-M0-report.md) |
| M1 | Transport + async `request` + decoding + completion bridge | `URLSessionTransport`, `RequestBuilder`, typed decode, `async/await` + completion APIs | [M1](.claude/PRPs/reports/swift-network-kit-M1-report.md) |
| M2 | Authentication | `AuthStrategy`, `TokenStorage` (Keychain / in-memory), actor `TokenManager`, single-flight 401 refresh | [M2](.claude/PRPs/reports/swift-network-kit-M2-report.md) |
| M3 | Retry, backoff, rate limiting | `RetryPolicy`, exponential backoff + jitter, idempotency-aware retry, `Retry-After`, `NetworkClock` + `TestClock` | [M3](.claude/PRPs/reports/swift-network-kit-M3-report.md) |
| M4 | Interceptors, tracing, logging, metrics | request/response interceptors, `TracingInterceptor`, redacting `NetworkLogger`, `InMemoryMetrics` | [M4](.claude/PRPs/reports/swift-network-kit-M4-report.md) |
| M5 | SSL / certificate pinning (optional) | `SSLPinning` (`.certificates` / `.publicKeys` / per-host / rotation / record-only), owns the `URLSession` delegate | [M5](.claude/PRPs/reports/swift-network-kit-M5-report.md) |
| M6 | Reachability | `NetworkMonitor` over `NWPathMonitor`, `AsyncStream` of `NetworkStatus`, `connectionRestored()` | [M6](.claude/PRPs/reports/swift-network-kit-M6-report.md) |
| M7 | Multipart, uploads, downloads, progress | `MultipartFormData` (RFC 7578), `client.upload` / `client.download`, byte `ProgressEvent` | [M7](.claude/PRPs/reports/swift-network-kit-M7-report.md) |
| M8 | HTTP caching | `CachePolicy`, memory + disk stores, ETag / `304`, stale-while-revalidate, network-failure fallback | [M8](.claude/PRPs/reports/swift-network-kit-M8-report.md) |
| M9 | Request management | cancel by id / `cancelAll`, GET/HEAD dedup, concurrency limit + priority queue, pause / resume | [M9](.claude/PRPs/reports/swift-network-kit-M9-report.md) |
| M10 | OAuth 2.0 + PKCE | `PKCE`, `AuthorizationCodeFlow` (URL build + token exchange), auto-refresh adapter | [M10](.claude/PRPs/reports/swift-network-kit-M10-report.md) |
| M11 | Offline request queue | opt-in `OfflineBehavior.queue`, persisted `FileOfflineStore`, FIFO replay on reconnect | [M11](.claude/PRPs/reports/swift-network-kit-M11-report.md) |
| M12 | Pagination + batch | `PaginatedEndpoint`, `client.paginate` / `collectAll`, parallel `zip` / `batch` | [M12](.claude/PRPs/reports/swift-network-kit-M12-report.md) |
| M13 | Mocking, tests, CI, docs | `MockNetworkTransport` matchers, `MockScenario`, `ArchitectureTests`, first CI, DocC landing | [M13](.claude/PRPs/reports/swift-network-kit-M13-report.md) |
| M14 | Combine + SwiftUI | `publisher(for:)` + upload/download/paginate publishers, `NetworkResource<Value>`, `Paged<Item>` | [M14](.claude/PRPs/reports/swift-network-kit-M14-report.md) |

Dependency spine: M0 -> M1 -> M2 -> M3 -> M4. M5, M6, M8, M10, M12 depend only on M1. M7 on M1.
M9 on M1 (+M2). M11 on M6 + M9. M14 on M1 (+M7, M12). M13 runs continuously.

## Toward 1.0.0

| Track | Work |
|---|---|
| API review | Freeze public names; audit `public` vs `package`; mark stable symbols; `@_spi` for test hooks that leak. |
| Docs | Per-area DocC articles (currently one landing page); host DocC on GitHub Pages from `release.yml`. |
| Coverage | Lift `Transport/` (session/task delegates ~30-55%) and `Testing/MockScenario` with `URLProtocolStub`-driven tests. Target 90% line. |
| CI hardening | Add a Linux job (Foundation-only subset), tvOS/watchOS/visionOS Simulator builds, a nightly `swift test` against the Swift `main` toolchain. |
| Perf | Benchmark the interceptor chain and cache-key hashing; `RequestBuilder` allocation profile. |

## Candidate post-1.0 features

- WebSocket / SSE endpoint type (`AsyncSequence` of frames), same `Endpoint` ergonomics.
- GraphQL helper layer (query + variables -> `Endpoint`, typed errors array).
- Background `URLSession` transfer support with the app-side completion-handler hook.
- Response body streaming (`client.stream(endpoint) -> AsyncSequence<Data>`) for large payloads.
- Pluggable serialization (Protobuf / MessagePack) behind the existing decode seam.
- A `swift-log` `LogHandler` bridge (opt-in product, keeps the core zero-dependency).
- Request/response fixtures recorder ("VCR") built on `URLProtocolStub`.

Nothing here is committed. Open an issue to discuss before starting.
