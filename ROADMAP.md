# Roadmap to 1.0.0 & Beyond

## Current Status

Feature-complete for the `0.1.0` series under Swift 6 strict concurrency. All core architectural subsystems are implemented with zero external dependencies:

- **Strict Concurrency & Sendable Core**: `NetworkClient`, `Endpoint`, `RequestBuilder`, immutable value types.
- **Actor-Isolated Token Lifecycle**: Single-flight 401 token refresh queue with loop guards and Keychain integration.
- **OAuth 2.0 PKCE**: RFC 7636 Authorization Code Flow and secure token exchange.
- **Enterprise Security**: Zero-dependency SPKI SHA-256 Public Key Pinning & Certificate pinning.
- **Resilient Offline Queue**: Persisted FIFO request replay with idempotency keys.
- **Streaming & Transfers**: RFC 7578 multipart disk streaming and `PaginatedEndpoint` AsyncSequence.
- **Telemetry & Metrics**: Microsecond-precision timing telemetry and RFC-compliant logging.

Detailed architectural documentation is available in [Documentation/Concurrency.md](Documentation/Concurrency.md). The marketing site source lives in [SwiftNetworkKit-web](https://github.com/ihusnainalii/SwiftNetworkKit-web).

---

## Release Cadence & Automated Versioning

SwiftNetworkKit uses **Conventional Commits** and **Google release-please** to automatically maintain releases:
- Every push to `main` updates a rolling release candidate pull request.
- Merging the release PR triggers automated GitHub Releases, SPM tag creation, and coverage publishing.

---

## Toward 1.0.0 (Stabilization & Polish)

| Track | Status | Description |
|---|---|---|
| **Public API Freeze** | In Progress | Finalize public API signatures; audit `public` vs `package` access; seal SPI test hooks. |
| **DocC Articles** | In Progress | Per-topic DocC articles published to GitHub Pages from the CI workflow. |
| **90% Line Coverage** | In Progress | Lift transport layer delegates and `MockScenario` tests with `URLProtocolStub`. |
| **Multi-Platform CI** | In Progress | Hardened matrix testing across iOS, macOS, tvOS, watchOS, visionOS, and Linux (Foundation-only). |
| **Performance Profiling** | Planned | Micro-benchmarks for interceptor chains, cache hashing, and `RequestBuilder` memory allocations. |

---

## Candidate Post-1.0 Features (Beyond 1.0)

The following architectural extensions are planned for 1.x and future major milestones:

- **WebSocket / SSE Stream**: Typed `AsyncSequence` of frames with native `Endpoint` ergonomics.
- **GraphQL Helper Layer**: Query and variables mapping to `Endpoint` with typed errors array.
- **Background Transfers**: `URLSessionDownloadTask` and `URLSessionUploadTask` with background session lifecycle events.
- **Response-Body Streaming**: `client.stream(endpoint) -> AsyncSequence<Data>` for real-time and large payload handling.
- **Pluggable Serialization**: Support for Protocol Buffers (Protobuf) and MessagePack behind the `DataDecoder` seam.
- **Logging Bridges**: Standalone `swift-log` `LogHandler` bridge product keeping the core library zero-dependency.
- **Network VCR Recorder**: Request/response cassette fixture recorder built on `URLProtocolStub`.

---

> [!NOTE]
> Have feedback or a feature proposal? Open an issue or discussion on [GitHub](https://github.com/ihusnainalii/SwiftNetworkKit/issues).

