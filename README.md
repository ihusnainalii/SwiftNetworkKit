# SwiftNetworkKit

A production-ready, composable networking layer for Apple platforms. Zero external dependencies,
Swift 6 strict concurrency, protocol-oriented and fully testable.

- **Version:** 0.1.0 (pre-release, API stabilizing toward 1.0.0)
- **Swift:** 6.0 (`swift-tools-version:6.0`, Swift 6 language mode)
- **Platforms:** iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+
- **Distribution:** Swift Package Manager
- **License:** Apache-2.0

[![CI](https://github.com/ihusnainalii/SwiftNetworkKit/actions/workflows/ci.yml/badge.svg)](https://github.com/ihusnainalii/SwiftNetworkKit/actions/workflows/ci.yml)
[![Release](https://github.com/ihusnainalii/SwiftNetworkKit/actions/workflows/release.yml/badge.svg)](https://github.com/ihusnainalii/SwiftNetworkKit/actions/workflows/release.yml)
[![Secret scan](https://github.com/ihusnainalii/SwiftNetworkKit/actions/workflows/gitleaks.yml/badge.svg)](https://github.com/ihusnainalii/SwiftNetworkKit/actions/workflows/gitleaks.yml)
[![codecov](https://codecov.io/gh/ihusnainalii/SwiftNetworkKit/branch/main/graph/badge.svg)](https://codecov.io/gh/ihusnainalii/SwiftNetworkKit)
[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![SPM](https://img.shields.io/badge/SPM-compatible-brightgreen.svg)](https://swift.org/package-manager)
[![Platforms](https://img.shields.io/badge/platforms-iOS%2016%20%7C%20macOS%2013%20%7C%20tvOS%2016%20%7C%20watchOS%209%20%7C%20visionOS%201-lightgrey.svg)](Package.swift)
[![License](https://img.shields.io/badge/license-Apache%202.0-blue.svg)](LICENSE)

---

## Table of contents

- [Overview](#overview)
- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Architecture](#architecture)
- [Core concepts](#core-concepts)
- [Defining an endpoint](#defining-an-endpoint)
- [Making requests](#making-requests)
- [Request configuration](#request-configuration)
- [Request body](#request-body)
- [Response handling](#response-handling)
- [Authentication](#authentication)
- [Token management](#token-management)
- [Automatic token refresh](#automatic-token-refresh)
- [OAuth 2.0](#oauth-20)
- [Security](#security)
- [Certificate and public-key pinning](#certificate-and-public-key-pinning)
- [Retry policy](#retry-policy)
- [Interceptors](#interceptors)
- [Request cancellation](#request-cancellation)
- [Request deduplication](#request-deduplication)
- [Network reachability](#network-reachability)
- [Caching](#caching)
- [Multipart upload](#multipart-upload)
- [File download](#file-download)
- [Progress tracking](#progress-tracking)
- [Offline request queue](#offline-request-queue)
- [Pagination and batch](#pagination-and-batch)
- [Combine and SwiftUI](#combine-and-swiftui)
- [Error handling](#error-handling)
- [Environment configuration](#environment-configuration)
- [Logging](#logging)
- [Metrics and observability](#metrics-and-observability)
- [Testing and mocking](#testing-and-mocking)
- [Thread safety](#thread-safety)
- [Performance](#performance)
- [Best practices](#best-practices)
- [Complete example](#complete-example)
- [Demos](#demos)
- [Versioning](#versioning)
- [Roadmap](#roadmap)
- [Contributing](#contributing)
- [Security policy](#security-policy)
- [License](#license)
- [Author](#author)

---

## Overview

SwiftNetworkKit is a reusable client networking layer you drop into an app instead of hand-rolling
`URLSession` plumbing per project. It exists because every app re-implements the same things badly:
token refresh races, retry with backoff, certificate pinning, request cancellation, response
caching, redacted logging, and a test seam.

**What it solves**

- One typed `Endpoint` per API operation, decoded straight into your model.
- A single `NetworkError` at the public boundary; every `URLError`, `DecodingError`, keychain
  `OSStatus`, and trust failure is mapped into it.
- A `TokenManager` actor that handles concurrent 401s with a single-flight refresh and request
  queueing, so ten simultaneous requests trigger exactly one refresh.
- Drop-in certificate pinning where the app ships a `.cer` and writes one line; the package owns
  the `URLSession` delegate.
- A test double (`MockNetworkTransport`) that ships in the library, so consumers never touch the
  network in unit tests.

**Who should use it**

App teams that want a consistent networking layer across projects, and anyone who needs pinning,
OAuth, offline queueing, or automatic refresh without pulling in a large framework.

**Design principles**

1. **Zero dependencies.** Foundation, and platform frameworks behind `#if canImport`.
2. **Composed, not a god object.** `NetworkClient` wires together small components
   (`RequestBuilder`, `TokenManager`, `InterceptorChain`, `RequestQueue`, caches, transport).
3. **Protocol-oriented.** Every collaborator is a protocol with a real adapter and a test double.
4. **Modern Swift.** ~95% async/await and actors under Swift 6 strict concurrency; Combine and
   SwiftUI are optional `#if canImport` adapters (see [Concurrency](Documentation/Concurrency.md)).
5. **Everything is configuration.** No hardcoded URLs, timeouts, or pins in the package.

---

## Features

- Async/await and completion-handler APIs
- Combine publishers (`#if canImport(Combine)`)
- SwiftUI `@Observable` load-state holders (iOS 17+)
- Generic `Decodable` / `Codable` decoding, plus `Data`, `String`, and empty responses
- Typed `Endpoint` abstraction with per-endpoint overrides
- Multi-environment configuration (development / QA / staging / production)
- Authentication: Bearer token, API key, Basic, custom
- Pluggable `TokenStorage` (in-memory, Keychain, custom)
- Actor-based `TokenManager`: single-flight 401 refresh, request queueing, loop guard, proactive refresh
- OAuth 2.0 Authorization Code flow with PKCE (RFC 7636)
- Configurable retry with exponential backoff, jitter, and idempotency awareness
- `Retry-After` rate-limit handling (429 / 503)
- SSL/TLS certificate pinning and public-key (SPKI) pinning, per-host, rotation-safe, record-only mode
- Request and response interceptors (adapt / retry / fail / substitute)
- Request cancellation by `Task` or by request ID
- Request deduplication for concurrent identical GETs
- Network reachability over `NWPathMonitor`, as an `AsyncStream`
- HTTP response caching: memory and disk stores, ETag / 304, `Cache-Control`, stale-while-revalidate
- Multipart uploads (RFC 7578), streamed from disk for large parts
- File downloads with a destination URL
- Upload and download byte-progress reporting
- Offline request queue: opt-in per endpoint, persisted, FIFO replay on reconnect
- Pagination as an `AsyncSequence`, plus parallel `zip` and `batch`
- Redacting logger with configurable levels; tokens never logged
- Metrics: counts, status-code histogram, average and p95 duration
- Request tracing: per-request `X-Request-ID`, logical-operation `X-Correlation-ID`
- Centralized HTTP status-code mapping
- Ships its own test doubles: `MockNetworkTransport`, `URLProtocolStub`, `TestClock`, `CapturingLogger`, `MockNetworkMonitor`, `InMemoryOfflineStore`

---

## Requirements

| | |
|---|---|
| Swift | 6.0 |
| Xcode | 16.0+ |
| iOS | 16.0+ |
| macOS | 13.0+ |
| tvOS | 16.0+ |
| watchOS | 9.0+ |
| visionOS | 1.0+ |
| Dependency manager | Swift Package Manager |

The Combine layer requires `Combine`. The SwiftUI helpers require the Observation framework
(iOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1). Both are `#if canImport`-gated, so the
package builds and works without them.

---

## Installation

### Swift Package Manager (Package.swift)

```swift
dependencies: [
    .package(url: "https://github.com/ihusnainalii/SwiftNetworkKit.git", from: "0.1.0")
],
targets: [
    .target(
        name: "MyApp",
        dependencies: [
            .product(name: "SwiftNetworkKit", package: "SwiftNetworkKit")
        ]
    )
]
```

### Xcode

File -> Add Package Dependencies, enter
`https://github.com/ihusnainalii/SwiftNetworkKit.git`, and pick "Up to Next Major Version"
from `0.1.0`.

Pre-1.0, a minor bump may include breaking changes; pin to `.upToNextMinor(from: "0.1.0")` if you
need stricter guarantees.

---

## Quick start

```swift
import SwiftNetworkKit

// 1. Configure once, inject everywhere.
let client = NetworkClient(
    configuration: NetworkConfiguration(
        baseURL: "https://api.example.com",
        headers: ["Accept": "application/json"]
    )
)

// 2. One type per API operation.
struct GetProfile: Endpoint {
    typealias Response = User
    var path: String { "/me" }
}

// 3. Call it.
let user: User = try await client.request(GetProfile())
```

---

## Architecture

```text
NetworkClient  (composition root, the only type you construct)
│
├── RequestBuilder ......... Endpoint + environment -> URLRequest (path params, query, headers, body)
├── InterceptorChain ....... request interceptors -> ... -> response interceptors
│     └── TracingInterceptor  (always first: X-Request-ID / X-Correlation-ID)
├── TokenManager (actor) ... single-flight 401 refresh, request queueing, proactive refresh
│     └── TokenStorage ...... InMemoryTokenStorage | KeychainTokenStorage | your own
├── RequestQueue (actor) ... concurrency limit + priority ordering, pause / resume
├── RequestRegistry (actor)  cancel-by-id bookkeeping
├── RequestDeduplicator ....  collapse concurrent identical GETs
├── RetryPolicy ............ backoff + jitter + Retry-After, idempotency-aware
├── ResponseCache .......... MemoryCacheStore | DiskCacheStore, ETag / 304 / SWR
├── NetworkTransport ....... URLSessionTransport (default) | MockNetworkTransport (tests)
│     └── ServerTrustEvaluator  certificate / public-key pinning via the URLSession delegate
├── OfflineRequestQueue .... persisted queue, replays FIFO on reconnect
├── NetworkLogger .......... ConsoleNetworkLogger over os.Logger, values run through Redactor
└── NetworkMetrics ......... InMemoryMetrics (counts, histogram, p95) | NoopMetrics
```

Each collaborator is a protocol. `NetworkClient` builds the default concrete graph from your
`NetworkConfiguration`; every seam accepts an override for testing. Full breakdown in
[Documentation/Concurrency.md](Documentation/Concurrency.md).

---

## Core concepts

| Type | Role |
|---|---|
| `NetworkClient` | The façade you call. Holds the configuration and the component graph. `Sendable`, share one instance. |
| `NetworkConfiguration` | Everything that shapes requests: environment, decoders, auth strategy, token storage, retry, interceptors, pinning, cache, concurrency, logger, metrics. A value type. |
| `NetworkEnvironment` | One deployment target: `kind`, `baseURL`, `defaultHeaders`, `timeout`, `logLevel`. |
| `Endpoint` | A protocol describing one API operation and its `Response` type. |
| `HTTPMethod` | `.get` / `.post` / `.put` / `.patch` / `.delete` / `.head` / `.options` / `.trace` / `.custom(String)`. |
| `HTTPHeaders` | Case-insensitive header map, `ExpressibleByDictionaryLiteral`. |
| `RequestBody` | `.json(Encodable)` / `.data` / `.string` / `.formURLEncoded` / `.multipart(MultipartFormData)`. |
| `QueryParameters` | Typed query values (`.string`, `.int`, `.bool`, arrays). |
| `NetworkError` | The single error type crossing the public boundary. |
| `ProgressEvent` | `completed` / `total` bytes, plus `fraction: Double?`. |
| `RequestID` | A `Sendable`, `Codable` handle for cancellation and offline replay. |

---

## Defining an endpoint

`Endpoint` has one required member, `associatedtype Response`, and one commonly overridden member,
`path`. Everything else has a default.

```swift
struct GetUser: Endpoint {
    typealias Response = User

    let id: Int
    var path: String { "/users/\(id)" }
}

struct SearchUsers: Endpoint {
    typealias Response = [User]

    let query: String
    var path: String { "/users" }
    var queryParameters: QueryParameters? { ["q": .string(query), "limit": .int(20)] }
}

struct UpdateProfile: Endpoint {
    typealias Response = User

    let draft: ProfileDraft
    var method: HTTPMethod { .patch }
    var path: String { "/me" }
    var body: RequestBody? { .json(draft) }
    var authentication: AuthRequirement { .required }
}
```

Path parameters are templated with `:name` and filled from `pathParameters`:

```swift
struct GetPost: Endpoint {
    typealias Response = Post
    let userID: Int
    let postID: Int
    var path: String { "/users/:userID/posts/:postID" }
    var pathParameters: [String: String] { ["userID": "\(userID)", "postID": "\(postID)"] }
}
```

Grouping operations in an enum works too:

```swift
enum UserAPI {
    struct Profile: Endpoint { typealias Response = User; var path: String { "/me" } }
    struct Update: Endpoint {
        typealias Response = User
        let draft: ProfileDraft
        var method: HTTPMethod { .patch }
        var path: String { "/me" }
        var body: RequestBody? { .json(draft) }
    }
}
```

### Overridable members

| Member | Default | Purpose |
|---|---|---|
| `baseURL` | `nil` (use the environment's) | Point one endpoint at a different host |
| `method` | `.get` | HTTP method |
| `headers` | `[:]` | Per-endpoint headers, merged over the environment's |
| `queryParameters` | `nil` | Typed query string |
| `pathParameters` | `[:]` | `:name` template substitutions |
| `body` | `nil` | Request body |
| `authentication` | `.none` | `.none` / `.required` / `.custom(AuthStrategy)` |
| `timeout` | `nil` (use the environment's) | Per-endpoint timeout |
| `priority` | `.normal` | Queue ordering when concurrency-limited |
| `retryPolicy` | `nil` (use the config's) | Per-endpoint retry override |
| `cachePolicy` | `nil` (use the config's) | Per-endpoint cache override |
| `deduplicate` | `nil` (use the config's) | Force dedup on/off for this endpoint |
| `skipRequestQueue` | `false` | Bypass the concurrency queue (use for the refresh call) |
| `offlineBehavior` | `.fail` | `.fail` or `.queue(expiresAfter:)` |
| `decoder` | `nil` (use the config's) | Per-endpoint `JSONDecoder` |
| `decode(_:response:using:)` | generic dispatch | Fully custom decoding |

---

## Making requests

### Async/await

```swift
let user: User = try await client.request(GetProfile())

// convenience helpers
let raw:  Data   = try await client.data(for: GetProfile())
let text: String = try await client.string(for: GetREADME())
try await client.send(DeleteAccount())        // ignores the body
```

### Completion handler

```swift
client.request(GetProfile()) { (result: Result<User, NetworkError>) in
    switch result {
    case .success(let user): ...
    case .failure(let error): ...
    }
}
```

### Combine

```swift
client.publisher(for: GetProfile())
    .receive(on: DispatchQueue.main)
    .sink(receiveCompletion: { ... }, receiveValue: { user in ... })
    .store(in: &cancellables)
```

### With an explicit request ID (for cancellation)

```swift
let id = RequestID()
async let profile = client.request(GetProfile(), id: id)
// later, from anywhere:
await client.cancel(id)
```

---

## Request configuration

Configuration is layered: **environment defaults** -> **endpoint overrides** -> **call site**.

```swift
var config = NetworkConfiguration(
    baseURL: "https://api.example.com",
    headers: ["Accept": "application/json"],
    timeout: 30
)
config.retry = .aggressive
config.maxConcurrentRequests = 4
config.enableDeduplication = true
config.cache = .memory(policy: .networkFirst)
config.metrics = InMemoryMetrics()
config.environment.logLevel = .basic

let client = NetworkClient(configuration: config)
```

| Concern | Where |
|---|---|
| Base URL, default headers, timeout, log level | `NetworkEnvironment` (via `NetworkConfiguration`) |
| Path / query / per-endpoint headers / body | `Endpoint` |
| Cache policy | `config.cache` default, `Endpoint.cachePolicy` override |
| Retry policy | `config.retry` default, `Endpoint.retryPolicy` override |
| Authentication | `config.authorization` + `Endpoint.authentication` |
| Pinning | `config.sslPinning` |
| Concurrency limit | `config.maxConcurrentRequests` |

---

## Request body

`RequestBody` cases:

```swift
var body: RequestBody? { .json(draft) }                        // Encodable -> application/json
var body: RequestBody? { .data(rawBytes, contentType: "application/octet-stream") }
var body: RequestBody? { .string("hello", contentType: "text/plain") }
var body: RequestBody? { .formURLEncoded(["grant_type": "refresh_token", "token": t]) }
var body: RequestBody? { .multipart(form) }                    // see Multipart upload
```

`.json` encodes with the configuration's `defaultEncoder` (or the endpoint's), which by default
converts to `snake_case` and encodes dates as ISO 8601. Override `NetworkConfiguration.defaultEncoder`
for different conventions.

---

## Response handling

`Response` can be:

| `Response` type | Behavior |
|---|---|
| `Decodable` / `Codable` | Decoded with the endpoint or configuration `JSONDecoder` |
| `Data` | Raw bytes, no decoding |
| `String` | UTF-8 decoded body |
| `EmptyResponse` | For 204 / empty-body endpoints |

Status handling is centralized: `2xx` succeeds; `401` -> `.unauthorized`, `403` -> `.forbidden`,
`404` -> `.notFound`, `422` -> `.validation`, `429` -> `.rateLimited(retryAfter:)`,
`5xx` -> `.server`, anything else unexpected -> `.unacceptableStatusCode(code, context)`. Every
error case carries a `ResponseContext` (status, headers, body, decoded server message) where one
exists.

Custom decoding for a non-JSON API:

```swift
struct GetProtobufThing: Endpoint {
    typealias Response = Thing
    var path: String { "/thing" }
    func decode(_ data: Data, response: HTTPURLResponse, using decoder: JSONDecoder) throws -> Thing {
        try Thing(serializedBytes: data)
    }
}
```

---

## Authentication

The strategy on the configuration decides how credentials attach; the requirement on the endpoint
decides whether they must.

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")

config.authorization = BearerAuth()                       // Authorization: Bearer <token from storage>
config.authorization = APIKeyAuth(key: "...", field: .header("X-API-Key"))
config.authorization = BasicAuth(username: "u", password: "p")
config.authorization = CustomAuth { request, _ in
    var r = request; r.setValue(sign(r), forHTTPHeaderField: "X-Signature"); return r
}
```

```swift
struct GetPublicFeed: Endpoint {
    typealias Response = Feed
    var path: String { "/feed" }
    var authentication: AuthRequirement { .none }          // default
}

struct GetInbox: Endpoint {
    typealias Response = [Message]
    var path: String { "/me/inbox" }
    var authentication: AuthRequirement { .required }      // must have a token; 401 triggers refresh
}
```

---

## Token management

Tokens live in a `TokenStorage`:

```swift
config.tokenStorage = InMemoryTokenStorage()                        // tests, or short-lived processes
config.tokenStorage = KeychainTokenStorage(service: "com.acme.app") // production; device-only by default
```

`KeychainTokenStorage` defaults to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (not synced
to iCloud, survives backgrounding). Override with the `accessibility:` parameter. A custom store is
any `TokenStorage` conformer (SQLite, an in-house secrets manager, and so on).

A `TokenPair` holds `accessToken`, optional `refreshToken`, and an optional `expiryDate` used for
proactive refresh.

---

## Automatic token refresh

Pass a `refresh` handler to `NetworkClient` and refresh becomes automatic:

```text
request  ->  401  ->  single-flight refresh  ->  store new TokenPair  ->  retry original request once
                                    │
       concurrent requests during refresh queue behind it, then resume with the new token
```

```swift
let client = NetworkClient(
    configuration: config,
    refresh: { storage in
        let old = try await storage.tokenPair()
        let new = try await myAuthAPI.exchange(refreshToken: old.refreshToken)
        return TokenPair(accessToken: new.access, refreshToken: new.refresh, expiryDate: new.expiry)
    },
    onSessionExpired: { await AppRouter.logout() }
)
```

Guarantees:

- **Single-flight.** Ten simultaneous 401s cause exactly one refresh call; the other nine await it.
- **Queued requests.** Requests started mid-refresh wait and then use the new token.
- **Loop guard.** A second 401 for the same request after a fresh token surfaces
  `NetworkError.sessionExpired` and calls `onSessionExpired` once.
- **Proactive refresh.** If the stored `TokenPair` has an `expiryDate`, the client refreshes
  `proactiveRefreshLeeway` seconds early (default 60) instead of waiting for a 401.
- **No deadlock.** The refresh request should set `skipRequestQueue = true` so a full concurrency
  queue plus an expired token cannot wedge.

---

## OAuth 2.0

Authorization Code flow with PKCE. The package builds the authorization URL and exchanges the code;
the app presents the URL (typically in `ASWebAuthenticationSession`) and captures the redirect.

```swift
let flow = AuthorizationCodeFlow(configuration: OAuthConfiguration(
    authorizationEndpoint: URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!,
    tokenEndpoint: URL(string: "https://oauth2.googleapis.com/token")!,
    clientID: "...",
    redirectURI: "myapp://callback",
    scopes: ["openid", "profile", "email"]
))

let state = AuthorizationCodeFlow.makeState()
let pkce  = PKCE()

let authURL = flow.authorizationURL(state: state, pkce: pkce)
// present authURL, receive redirectURL

let code   = try flow.authorizationCode(fromRedirect: redirectURL, expectedState: state)
let tokens = try await flow.exchange(code: code, pkce: pkce)

// hand automatic refresh to the client:
let client = NetworkClient(configuration: config, refresh: flow.tokenManagerRefreshHandler())
```

- `code_verifier` is 43 to 128 characters from a CSPRNG; `code_challenge` is
  `base64url(SHA256(verifier))` (RFC 7636).
- `state` mismatch on the redirect throws before any token exchange.
- OAuth is entirely optional; nothing else in the package depends on it.

---

## Security

| Area | What SwiftNetworkKit does |
|---|---|
| Transport | System TLS via `URLSession` (TLS 1.2 floor). No ATS exceptions, no `allowsArbitraryLoads`. |
| Cryptography | SHA-256 only, via `CryptoKit`. No MD5 / SHA-1 / DES / RC4 / ECB anywhere. |
| Randomness | `SecRandomCopyBytes` for PKCE; `SystemRandomNumberGenerator` (CSPRNG on Apple platforms) elsewhere. |
| Certificate pinning | Opt-in, additive to system chain validation, fails closed. See below. |
| Token storage | Keychain, device-only, not iCloud-synced by default. |
| Logging | `Redactor` strips `Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, and token-bearing body keys at every log level. |
| At-rest | Disk cache and offline queue write with `.completeFileProtectionUnlessOpen` (encrypted while the device is locked). |
| Deserialization | `NSKeyedUnarchiver.unarchivedObject(ofClass:)` (secure coding) for archived requests; `JSONDecoder` only for responses. |
| CI | `gitleaks` secret scan, SwiftLint `--strict` (`force_cast` / `force_try` are errors), ThreadSanitizer + AddressSanitizer. |

Full review: [Documentation/SecurityAudit.md](Documentation/SecurityAudit.md). Reporting a
vulnerability: [SECURITY.md](SECURITY.md).

---

## Certificate and public-key pinning

The app ships its `.cer` / `.der` files and writes one line. The package owns the `URLSession`
delegate, challenge handling, and trust evaluation.

```swift
var config = NetworkConfiguration(baseURL: "https://api.acme.com")

// pin the leaf/intermediate certificate (bundle it as a resource):
config.sslPinning = .certificateResources(["acme-2025", "acme-2026"])

// or pin the public key (SPKI SHA-256), which survives certificate renewal with the same key:
config.sslPinning = .publicKeys(["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="], hosts: ["api.acme.com"])

// or discover the values first (never blocks; logs the sha256/... to paste above):
config.sslPinning = .development(.publicKeys([]))

// default:
config.sslPinning = .disabled          // normal system TLS, no delegate installed
```

- The system chain is validated (`SecTrustEvaluateWithError`) **before** pin matching; pinning is
  additive, not a replacement.
- A mismatch fails the request with `NetworkError.sslPinningFailed(host:)` and never falls back to
  "allow".
- Multiple pins per host support certificate rotation: deploy the new pin alongside the old, then
  remove the old after the cert rolls.
- A missing resource or malformed hash fails `NetworkClient` initialization, not silently at
  request time.
- `.development` / record-only mode logs the observed pins and allows the connection, for adoption.

---

## Retry policy

```swift
config.retry = .default        // 3 attempts, exponential backoff + full jitter, respects Retry-After
config.retry = .none           // 1 attempt
config.retry = .aggressive     // more attempts, wider backoff

config.retry = RetryPolicy(
    maxAttempts: 4,
    retryableStatusCodes: [408, 429, 500, 502, 503, 504],
    backoff: .exponential(base: 0.5, multiplier: 2, max: 30),
    jitter: .full,
    respectRetryAfter: true,
    maxRetryAfterDelay: 120,
    retryNonIdempotent: false
)
```

- **Idempotency-aware.** `GET` / `HEAD` / `PUT` / `DELETE` retry by default; `POST` / `PATCH` do
  not, unless `retryNonIdempotent: true` or the endpoint opts in.
- **Rate limiting.** `429` and `503` with a `Retry-After` header wait exactly that long (capped at
  `maxRetryAfterDelay`), overriding the backoff curve.
- **Per-endpoint override:**

```swift
struct SubmitOrder: Endpoint {
    typealias Response = Order
    var method: HTTPMethod { .post }
    var retryPolicy: RetryPolicy? { RetryPolicy(retryNonIdempotent: true) }   // this POST is safe to repeat
}
```

Timing goes through a `NetworkClock` port, so retry logic is unit-tested with `TestClock` and no
real waiting.

---

## Interceptors

```text
Endpoint
  -> request interceptors (in order)      adapt headers, sign, add tracing
  -> authentication
  -> transport (URLSession / pinning)
  -> status mapping
  -> response interceptors (in order)     inspect, retry, fail, or substitute
  -> decode
  -> caller
```

```swift
struct AppVersionInterceptor: RequestInterceptor {
    func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
        var r = request
        r.setValue(Bundle.main.appVersion, forHTTPHeaderField: "X-App-Version")
        return r
    }
}

struct TwoFactorInterceptor: ResponseInterceptor {
    func process(_ response: InterceptorResponse, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
        guard response.statusCode == 428 else { return .proceed }
        try await promptForOTP()
        return .retry           // .proceed / .retry / .fail(NetworkError) / .substitute(Data, HTTPURLResponse)
    }
}

config.requestInterceptors  = [AppVersionInterceptor()]
config.responseInterceptors = [TwoFactorInterceptor()]
```

`TracingInterceptor` is always installed first and adds `X-Request-ID` to every request.

---

## Request cancellation

```swift
// 1. Task cancellation cascades to the URLSession task.
let task = Task { try await client.request(GetProfile()) }
task.cancel()

// 2. Cancel by ID from anywhere.
let id = RequestID()
Task { try await client.request(GetFeed(), id: id) }
await client.cancel(id)

// 3. Cancel everything in flight.
await client.cancelAll()
```

A cancelled request throws `NetworkError.cancelled`.

---

## Request deduplication

When enabled, concurrent identical `GET` / `HEAD` requests share one in-flight network call.

```text
Request A ─┐
Request B ─┼──► one URLSession request ──► response fanned out to A, B, C
Request C ─┘
```

```swift
config.enableDeduplication = true               // global
// or per endpoint:
struct GetConfig: Endpoint {
    typealias Response = AppConfig
    var path: String { "/config" }
    var deduplicate: Bool? { true }
}
```

Deduplication keys on method + URL (+ auth state). It never applies to non-idempotent methods or
anything user-specific.

---

## Network reachability

```swift
let monitor = PathNetworkMonitor()
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.networkMonitor = monitor

for await status in await monitor.statusUpdates() {
    switch status {
    case .satisfied(let interface):   // .wifi / .cellular / .wiredEthernet / .other
        print("online via \(interface)")
    case .unsatisfied, .requiresConnection:
        print("offline")
    }
}

for await _ in await monitor.connectionRestored() {
    // fires each time connectivity returns after a drop
}
```

`NetworkStatusBroadcaster` fans one `NWPathMonitor` out to many `AsyncStream` consumers. In tests,
inject `MockNetworkMonitor` and call `send(.unsatisfied)` / `send(.satisfied(.wifi))`.

---

## Caching

```swift
config.cache = .memory(policy: .cacheFirst)

config.cache = CacheConfiguration(
    store: DiskCacheStore(),                 // survives launches; LRU by total size
    defaultPolicy: .staleWhileRevalidate,
    defaultTTL: 300
)
```

| Policy | Behavior |
|---|---|
| `.ignoreCache` | Always network, do not read or write the cache |
| `.networkOnly` | Network, but write the response to the cache |
| `.cacheFirst` | Fresh cache hit returns immediately; otherwise network |
| `.networkFirst` | Network, falling back to a cached response if it fails |
| `.cacheOnly` | Cache or a `.notFound`-style failure; never touches the network |
| `.staleWhileRevalidate` | Return the cached response now, refresh in the background |

- Only `GET` / `HEAD` are cached.
- `ETag` responses are revalidated with `If-None-Match`; a `304` reuses the stored body.
- `Cache-Control: no-store` is never persisted; `max-age` and `no-cache` are honored.
- Per-endpoint override via `Endpoint.cachePolicy`.

---

## Multipart upload

```swift
var form = MultipartFormData()
form.append("A caption", name: "caption")
form.append(jpegData, name: "photo", fileName: "cat.jpg", mimeType: "image/jpeg")
form.append(fileURL, name: "video")           // streamed from disk, not loaded into memory

let created: Photo = try await client.upload(CreatePhoto(), from: .multipart(form)) { event in
    print(event.fraction ?? 0)                // 0.0 ... 1.0
}
```

- RFC 7578 boundary construction, per-part `Content-Type`, `Content-Disposition`.
- Large file parts stream from disk.
- Uploads are not retried and skip the 401-refresh hop; a partial upload is unsafe to replay.
- An in-memory body can also be sent with `.data` or `.file`:

```swift
try await client.upload(PutAvatar(), from: .data(pngData))
try await client.upload(PutAvatar(), from: .file(localURL))
```

---

## File download

```swift
let destination = URL.documentsDirectory.appending(path: "report.pdf")

let fileURL = try await client.download(GetExport(), to: destination) { event in
    print("\(event.completed) / \(event.total) bytes")
}
```

- Pass `to:` for a specific destination, or omit it to get the transport's temp file URL (move it
  before the next run).
- Cancellation via `Task` cancellation or request ID, same as any request.
- Background `URLSession` transfers need app-side wiring and are not handled automatically.

---

## Progress tracking

Both `upload` and `download` take a trailing `@Sendable (ProgressEvent) -> Void` closure.

```swift
public struct ProgressEvent: Sendable, Hashable {
    public let completed: Int64
    public let total: Int64            // -1 if the server sent no Content-Length
    public var fraction: Double?       // completed / total, or nil when total is unknown
}
```

The closure is called on an arbitrary executor; hop to the main actor for UI:

```swift
try await client.download(GetExport(), to: dest) { event in
    Task { @MainActor in self.progress = event.fraction ?? 0 }
}
```

For Combine, `uploadPublisher` / `downloadPublisher` emit `.progress(ProgressEvent)` values then a
final `.finished(...)`.

---

## Offline request queue

Opt-in per endpoint. A request sent while offline is archived and the caller gets
`NetworkError.offlineQueued(id)` immediately; the queue replays FIFO when connectivity returns.

```swift
config.offlineStore   = FileOfflineStore()          // persisted; survives launches
config.networkMonitor = PathNetworkMonitor()

struct SubmitOrder: Endpoint {
    typealias Response = Order
    var method: HTTPMethod { .post }
    var offlineBehavior: OfflineBehavior { .queue(expiresAfter: 3600) }
}
```

```swift
for await event in await client.offlineReplayEvents() {
    switch event {
    case .replayed(let id, let statusCode): ...
    case .failed(let id, let error): ...
    case .expired(let id): ...
    }
}

await client.replayOfflineQueue()   // also force a replay manually
```

Multipart bodies cannot be archived, so a multipart endpoint always fails fast instead of queueing.

---

## Pagination and batch

```swift
struct ListUsers: PaginatedEndpoint {
    typealias Response = [User]
    var page = 1
    var path: String { "/users" }
    var queryParameters: QueryParameters? { ["_page": .int(page), "_limit": .int(20)] }

    func items(from response: [User]) -> [User] { response }
    func nextPage(after response: [User]) -> Self? {
        guard !response.isEmpty else { return nil }
        var next = self; next.page += 1; return next
    }
}

for try await pageOfUsers in client.paginate(ListUsers()) { ... }   // one array per page
let everyone = try await client.collectAll(ListUsers(), max: 500)   // flattened, capped
```

`nextPage(after:)` gives the endpoint full control of the scheme (page number, cursor, `Link:`
header). `paginate` honors task cancellation and caps at `maxPages` (default 1000).

Parallel requests:

```swift
let (profile, feed) = try await client.zip(GetProfile(), GetFeed())
let items = await client.batch(ids.map { GetItem(id: $0) })   // [Result<Item, NetworkError>]
```

---

## Combine and SwiftUI

### Combine (`#if canImport(Combine)`)

```swift
client.publisher(for: GetProfile())                            // one value, then completion
client.paginatePublisher(ListUsers())                          // one value per page
client.uploadPublisher(CreatePhoto(), from: .multipart(form))  // .progress(_) ... .finished(Response)
client.downloadPublisher(GetExport(), to: dest)                // .progress(_) ... .finished(URL)
```

Values arrive on whatever executor the request finished on; call `.receive(on:)` yourself for UI.
Cancelling the subscription cancels the underlying `Task`.

### SwiftUI (iOS 17+, `#if canImport(Observation)`)

```swift
@MainActor
struct UsersScreen: View {
    let client: NetworkClient
    @State private var users: NetworkResource<[User]>
    @State private var feed: Paged<Post>

    init(client: NetworkClient) {
        self.client = client
        _users = State(wrappedValue: NetworkResource(client: client))
        _feed = State(wrappedValue: Paged(client: client))
    }

    var body: some View {
        List {
            ForEach(users.value ?? []) { user in Text(user.name) }
            ForEach(feed.items) { post in
                PostRow(post: post)
                    .onAppear { Task { await feed.loadMoreIfNeeded(currentItem: post) } }
            }
            if feed.isLoadingMore { ProgressView() }
        }
        .overlay { if users.isLoading { ProgressView() } }
        .task {
            await users.load(ListUsers())
            await feed.start(FeedPage())
        }
        .refreshable { await users.reload() }
    }
}
```

`NetworkResource<Value>` exposes `phase` (`idle` / `loading` / `loaded` / `failed`), `value`,
`error`, `isLoading`. `load(_:)` cancels the previous request and keeps the last value visible
while reloading. There is no `ObservableObject` fallback for iOS 16; an iOS-16 app models this with
its own `@Observable` view models (see the SwiftUI demo).

---

## Error handling

Every failure that crosses the public boundary is a `NetworkError`:

```text
NetworkError
├── invalidURL(String)
├── noInternet
├── timeout
├── unauthorized(ResponseContext)
├── forbidden(ResponseContext)
├── notFound(ResponseContext)
├── validation(ResponseContext)
├── rateLimited(retryAfter: TimeInterval?, ResponseContext)
├── server(ResponseContext)
├── unacceptableStatusCode(Int, ResponseContext)
├── decoding(underlying: Error, ResponseContext?)
├── encoding(underlying: Error)
├── sslPinningFailed(host: String)
├── tokenRefreshFailed(underlying: Error)
├── sessionExpired
├── cancelled
├── offline
├── offlineQueued(RequestID)
├── transport(underlying: Error)
└── unknown(underlying: Error?)
```

Switch on the stable `code` discriminant, and read the response context when present:

```swift
do {
    let user = try await client.request(GetProfile())
} catch let error as NetworkError {
    switch error.code {
    case .unauthorized, .sessionExpired:
        await AppRouter.logout()
    case .notFound:
        showNotFound()
    case .validation:
        show(error.serverMessage ?? "Invalid input")   // decoded from the response body
    case .noInternet, .offline:
        showOfflineBanner()
    case .rateLimited:
        // error.responseHeaders?["Retry-After"]
        scheduleRetryLater()
    default:
        showGeneric(error)
    }
    // error.statusCode, error.responseHeaders, error.responseData also available
}
```

`NetworkError.normalize(_:)` maps an arbitrary thrown error into this type if you catch something
loosely typed.

---

## Environment configuration

```swift
let dev = NetworkEnvironment.development(
    baseURL: URL(string: "https://dev.api.example.com")!,
    headers: ["X-Env": "dev"]
)
let prod = NetworkEnvironment.production(
    baseURL: URL(string: "https://api.example.com")!
)

#if DEBUG
let environment = dev
#else
let environment = prod
#endif

var config = NetworkConfiguration(environment: environment)
config.environment.logLevel = environment.kind == .production ? .error : .debug
config.sslPinning = environment.kind == .production ? .certificateResources(["api"]) : .disabled
```

`EnvironmentKind` is `.development` / `.qa` / `.staging` / `.production`. Each environment sets its
own base URL, default headers, timeout, and log level.

---

## Logging

```swift
config.environment.logLevel = .basic    // .none / .error / .basic / .verbose / .debug
config.logger = ConsoleNetworkLogger()  // default; writes to os.Logger
config.redactedHeaders = ["x-internal-signature"]
config.redactedBodyKeys = ["ssn", "card_number"]
```

| Level | Emits |
|---|---|
| `.none` | nothing |
| `.error` | failures only |
| `.basic` | method, URL, status, duration |
| `.verbose` | + redacted headers |
| `.debug` | + redacted bodies |

`Authorization`, `Cookie`, `Set-Cookie`, `X-API-Key`, and common token body keys are always
redacted, at every level. A custom sink is any `NetworkLogger` conformer (ship logs to your
aggregator, and so on).

---

## Metrics and observability

```swift
let metrics = InMemoryMetrics()
config.metrics = metrics

let snapshot = await metrics.snapshot()
snapshot.requestCount
snapshot.successCount
snapshot.failureCount
snapshot.statusCodeHistogram       // [200: 431, 404: 3, 500: 1]
snapshot.averageDuration
snapshot.p95Duration
snapshot.retryCount
snapshot.tokenRefreshCount
```

Tracing:

- Every request carries a unique `X-Request-ID`.
- Wrap a logical operation so its requests share one `X-Correlation-ID`:

```swift
try await client.withCorrelation("checkout-\(orderID)") {
    _ = try await client.request(CreateOrder(draft))
    _ = try await client.request(ChargeCard(orderID))
}
```

`InMemoryMetrics` is an actor you inspect in tests; `NoopMetrics` is the default. A custom
`NetworkMetrics` conformer forwards events to your APM.

---

## Testing and mocking

Test doubles ship in the library. Nothing touches the network in a unit test.

```swift
import Testing
@testable import SwiftNetworkKit

@Test func decodesTheProfile() async throws {
    let transport = MockNetworkTransport()
        .enqueueJSON(User(id: 1, name: "Ada"), status: 200)

    let client = NetworkClient(
        configuration: NetworkConfiguration(baseURL: "https://example.com"),
        transport: transport
    )

    let user = try await client.request(GetProfile())
    #expect(user.name == "Ada")
}
```

### Simulating status codes and conditions

```swift
let transport = MockNetworkTransport()
    .enqueue(.status(500))                      // then...
    .enqueue(.status(429, headers: ["Retry-After": "2"]))
    .enqueue(.error(URLError(.notConnectedToInternet)))
    .enqueueJSON(order, status: 201)

// order-independent matchers instead of a FIFO queue:
let matched = MockNetworkTransport()
    .stub(method: .get, pathContains: "/me", with: .json(user))
    .stub(method: .post, pathContains: "/orders", with: .status(201))
```

### Scenario presets

```swift
let client = NetworkClient(
    configuration: config,
    transport: MockScenario.tokenExpired(body: userJSON).transport()
)
// .happyPath / .tokenExpired / .offline / .rateLimited / .serverErrors
```

### Other doubles

| Double | Use |
|---|---|
| `URLProtocolStub` | Exercise the real `URLSessionTransport` wiring against canned responses |
| `TestClock` | Drive retry / backoff / proactive-refresh timing with `advance(by:)`, no real waiting |
| `CapturingLogger` | Assert on emitted log lines (and that tokens are absent) |
| `MockNetworkMonitor` | Push `.satisfied` / `.unsatisfied` into reachability streams |
| `InMemoryOfflineStore` | Offline-queue tests without touching disk |

### Dependency injection

Inject the `NetworkClient` (or a protocol you define over it) into your repositories, and swap the
transport in tests. The SwiftUI demo shows an `AppContainer` wiring pattern.

---

## Thread safety

- `NetworkClient` is `Sendable`. Construct one and share it.
- Shared mutable state lives in actors: `TokenManager`, `RequestQueue`, `RequestRegistry`,
  `RequestDeduplicator`, the cache stores, `InMemoryMetrics`, `OfflineRequestQueue`.
- The concurrent 401 case is handled by `TokenManager`'s single-flight refresh; there is an
  explicit deadlock test for "full queue plus expired token".
- The only `@unchecked Sendable` types are the three `URLSession` delegate shims (whose callbacks
  are not `async`) and the test doubles; each guards a few lines with a lock and a comment.
- SwiftUI `NetworkResource` / `Paged` are `@MainActor`.
- The whole test suite runs green under ThreadSanitizer in CI.

Details: [Documentation/Concurrency.md](Documentation/Concurrency.md).

---

## Performance

- `URLSession` connection reuse is preserved (one session per client, plus a dedicated session per
  upload/download for progress delegation).
- `maxConcurrentRequests` (default 6, matching the `URLSession` per-host limit) bounds in-flight
  work; extra requests queue by `Endpoint.priority`.
- Deduplication removes redundant identical GETs.
- The cache short-circuits the network entirely for fresh `cacheFirst` / `cacheOnly` hits.
- Large multipart parts and downloads stream from and to disk rather than loading into memory.
- Retry timing is computed, not busy-waited (`NetworkClock`).

---

## Best practices

- Define one typed `Endpoint` per API operation; decode straight into your models.
- Inject the `NetworkClient` (or a wrapper protocol) so features are unit-testable.
- Never hardcode tokens or base URLs; use `NetworkEnvironment` and `TokenStorage`.
- Use `KeychainTokenStorage` in production; keep `InMemoryTokenStorage` for tests.
- Pin the public key, not the certificate, and always deploy two pins so a rotation is not an
  outage.
- Do not blindly enable `retryNonIdempotent`; make each `POST` opt in only when it is genuinely
  safe to repeat.
- Set `skipRequestQueue = true` on the token-refresh endpoint.
- Keep sensitive fields out of logs by adding them to `redactedBodyKeys`.
- Hop progress and completion callbacks to `@MainActor` before touching UI state.
- Treat `NetworkError.sessionExpired` as your single "log the user out" signal.

---

## Complete example

A login, an authenticated call, an automatic refresh on expiry, and typed error handling.

```swift
import SwiftNetworkKit

// MARK: Models

struct Credentials: Encodable { let email: String; let password: String }
struct Session: Decodable { let accessToken: String; let refreshToken: String; let expiresIn: Int }
struct User: Decodable { let id: Int; let name: String; let email: String }

// MARK: Endpoints

struct LogIn: Endpoint {
    typealias Response = Session
    let credentials: Credentials
    var method: HTTPMethod { .post }
    var path: String { "/auth/login" }
    var body: RequestBody? { .json(credentials) }
}

struct RefreshSession: Endpoint {
    typealias Response = Session
    let refreshToken: String
    var method: HTTPMethod { .post }
    var path: String { "/auth/refresh" }
    var body: RequestBody? { .formURLEncoded(["refresh_token": refreshToken]) }
    var skipRequestQueue: Bool { true }          // must not deadlock behind a full queue
}

struct GetMe: Endpoint {
    typealias Response = User
    var path: String { "/me" }
    var authentication: AuthRequirement { .required }
}

// MARK: Wiring

@MainActor
final class AccountService {
    private let client: NetworkClient
    private let storage = KeychainTokenStorage(service: "com.acme.app")

    init(environment: NetworkEnvironment) {
        var config = NetworkConfiguration(environment: environment)
        config.tokenStorage = storage
        config.retry = .default
        config.metrics = InMemoryMetrics()
        if environment.kind == .production {
            config.sslPinning = .publicKeys(["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA="], hosts: ["api.acme.com"])
        }

        // capture nothing that would retain self; the refresh handler is @Sendable
        let refreshClient = NetworkClient(configuration: config)
        self.client = NetworkClient(
            configuration: config,
            refresh: { storage in
                let current = try await storage.tokenPair()
                let renewed = try await refreshClient.request(RefreshSession(refreshToken: current.refreshToken ?? ""))
                return TokenPair(
                    accessToken: renewed.accessToken,
                    refreshToken: renewed.refreshToken,
                    expiryDate: Date().addingTimeInterval(TimeInterval(renewed.expiresIn))
                )
            },
            onSessionExpired: { await AppRouter.shared.logout() }
        )
    }

    func logIn(email: String, password: String) async throws {
        let session = try await client.request(LogIn(credentials: .init(email: email, password: password)))
        try await storage.setTokenPair(TokenPair(
            accessToken: session.accessToken,
            refreshToken: session.refreshToken,
            expiryDate: Date().addingTimeInterval(TimeInterval(session.expiresIn))
        ))
    }

    /// If the access token has expired, this call triggers exactly one refresh, waits for it,
    /// retries once, and returns the user. Concurrent callers share that single refresh.
    func currentUser() async throws -> User {
        do {
            return try await client.request(GetMe())
        } catch let error as NetworkError where error.code == .sessionExpired {
            throw AppError.mustReauthenticate            // refresh itself failed
        }
    }
}
```

---

## Demos

**CLI tour** ([`Sources/NetworkKitDemo/`](Sources/NetworkKitDemo/)): a scripted run through every
feature against the public `jsonplaceholder.typicode.com` API.

```bash
swift run NetworkKitDemo             # live API
swift run NetworkKitDemo --offline   # auth + refresh section only, no network
```

**SwiftUI app** ([`Examples/SwiftUIDemo/`](Examples/SwiftUIDemo/)): a standalone iOS app (MVVM +
Clean Architecture) with a searchable paginated user list, a detail screen, a POST form, an image
downloader with a live progress bar, and a Diagnostics screen (client config, connectivity,
metrics, and a narrated 401 to refresh to retry walkthrough).

```bash
xcodebuild -project Examples/SwiftUIDemo/SwiftUIDemo.xcodeproj \
  -scheme SwiftUIDemo -destination 'generic/platform=iOS Simulator' build
```

---

## Versioning

[Semantic Versioning](https://semver.org). Pre-1.0, a **minor** bump may include breaking changes;
**patch** bumps are always backward compatible.

Releases are automated: every merge to `main` updates a rolling release pull request (version bump
plus a `CHANGELOG.md` section generated from the [Conventional Commit](https://www.conventionalcommits.org)
history). Merging that pull request tags `vX.Y.Z` and publishes a GitHub Release. See
[CHANGELOG.md](CHANGELOG.md) and [CONTRIBUTING.md](CONTRIBUTING.md).

---

## Roadmap

See [ROADMAP.md](ROADMAP.md). Toward 1.0: public API freeze, per-topic DocC articles, higher
coverage on the transport delegates, and Linux plus tvOS/watchOS/visionOS CI. Candidate post-1.0
features include WebSocket / SSE endpoints, response-body streaming, a background-transfer hook,
and a `swift-log` bridge (as a separate product, keeping the core dependency-free).

---

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md). In short: zero dependencies, one primary type per file,
Swift 6 strict concurrency, Conventional Commits, and every change stays green under
`swift build -warnings-as-errors`, `swift test`, ThreadSanitizer, SwiftLint `--strict`, and
`swift format lint --strict`.

```bash
swift build -Xswiftc -warnings-as-errors
swift test --parallel
swift test --sanitize=thread
swiftlint --strict
swift format lint -r -s --configuration .swift-format Sources Tests
bash scripts/coverage.sh
```

---

## Security policy

See [SECURITY.md](SECURITY.md) for supported versions, the package's security posture, and how to
privately report a vulnerability. A standing review lives in
[Documentation/SecurityAudit.md](Documentation/SecurityAudit.md).

---

## License

Apache-2.0. See [LICENSE](LICENSE).

---

## Author

**Husnain Ali** ([GitHub @ihusnainalii](https://github.com/ihusnainalii))
