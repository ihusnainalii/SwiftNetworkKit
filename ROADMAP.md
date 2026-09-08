# Roadmap

## Status

Feature-complete for a `0.1.0` pre-release. The full feature set is listed in the
[README](README.md#features); an architectural breakdown is in
[Documentation/Concurrency.md](Documentation/Concurrency.md). The remaining work before `1.0.0` is
API review, documentation polish, and soak time.

## Toward 1.0.0

| Track | Work |
|---|---|
| API review | Freeze public names; audit `public` vs `package`; mark stable symbols; `@_spi` for test hooks that currently leak into the public surface. |
| Documentation | Per-topic DocC articles (currently one landing page); publish DocC to GitHub Pages from the release workflow. |
| Coverage | Lift the transport layer (`URLSession` session/task delegates, ~30 to 55%) and `MockScenario` with `URLProtocolStub`-driven tests. Target 90% line coverage. |
| CI hardening | Add a Linux job (Foundation-only subset), tvOS / watchOS / visionOS Simulator builds, and a nightly run against the Swift `main` toolchain. |
| Performance | Benchmark the interceptor chain and cache-key hashing; profile `RequestBuilder` allocations. |

## Candidate post-1.0 features

- WebSocket / SSE endpoint type (an `AsyncSequence` of frames) with the same `Endpoint` ergonomics.
- GraphQL helper layer (query plus variables to `Endpoint`, typed errors array).
- Background `URLSession` transfer support with an app-side completion-handler hook.
- Response-body streaming (`client.stream(endpoint) -> AsyncSequence<Data>`) for large payloads.
- Pluggable serialization (Protobuf / MessagePack) behind the existing decode seam.
- A `swift-log` `LogHandler` bridge, shipped as a separate product so the core stays dependency-free.
- A request/response fixture recorder ("VCR") built on `URLProtocolStub`.

Nothing here is committed. Open an issue to discuss before starting.
