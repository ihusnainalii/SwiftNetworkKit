# SwiftNetworkKit — Comprehensive API Reference

_Scope: SwiftNetworkKit v0.1.0 • Swift 6 Language Mode • Zero External Dependencies_

This document is the definitive API reference for `SwiftNetworkKit`, detailing all public types, protocols, actors, structs, enums, error models, and integration points across all 14 engineering milestones (M0 through M14).

---

## Table of Contents

1. [Architectural Overview & Concurrency Model](#architectural-overview--concurrency-model)
2. [Module M0: Core Types & Endpoint DSL](#module-m0-core-types--endpoint-dsl)
3. [Module M1: Request Pipeline & Transport Layer](#module-m1-request-pipeline--transport-layer)
4. [Module M2: Authentication & Token Management](#module-m2-authentication--token-management)
5. [Module M3: Resiliency, Retry & Exponential Backoff](#module-m3-resiliency-retry--exponential-backoff)
6. [Module M4: Observability, Interceptors & Redacting Logger](#module-m4-observability-interceptors--redacting-logger)
7. [Module M5: Security & SPKI Certificate Pinning](#module-m5-security--spki-certificate-pinning)
8. [Module M6: Connectivity & Network Reachability](#module-m6-connectivity--network-reachability)
9. [Module M7: Multipart Form, Upload & Download Progress](#module-m7-multipart-form-upload--download-progress)
10. [Module M8: Policy-Driven HTTP Response Caching](#module-m8-policy-driven-http-response-caching)
11. [Module M9: Request Lifecycle, Deduplication & Priority](#module-m9-request-lifecycle-deduplication--priority)
12. [Module M10: OAuth 2.0 PKCE Engine](#module-m10-oauth-20-pkce-engine)
13. [Module M11: Persisted Offline Request Queue](#module-m11-persisted-offline-request-queue)
14. [Module M12: AsyncSequence Pagination & Parallel Batching](#module-m12-asyncsequence-pagination--parallel-batching)
15. [Module M13: Test Doubles, Stubs & Mock Scenarios](#module-m13-test-doubles-stubs--mock-scenarios)
16. [Module M14: Combine Publishers & SwiftUI @Observable](#module-m14-combine-publishers--swiftui-observable)

---

## Architectural Overview & Concurrency Model

SwiftNetworkKit is architected natively around **Swift 6 Strict Concurrency** and Apple Silicon modern runtimes.

- **Strict Isolation**: 13 isolated Swift actors protect shared state (`TokenManager`, `DiskCacheStore`, `MemoryCacheStore`, `OfflineRequestQueue`, `RequestDeduplicator`, `RequestRegistry`, etc.).
- **Zero Locks for Domain Logic**: Locks (`NSLock`) are strictly localized to non-async `URLSessionDelegate` bridge callbacks.
- **Value Semantics**: Endpoints, configurations, request bodies, metrics, and errors are immutable `Sendable` value types.
- **Cooperative Cancellation**: Every operation hooks into `withTaskCancellationHandler` to automatically tear down network sockets upon task cancellation.

---

## Module M0: Core Types & Endpoint DSL

### `Endpoint` Protocol
The primary contract for defining type-safe HTTP requests.

```swift
public protocol Endpoint: Sendable {
    associatedtype Response: Decodable & Sendable

    var path: String { get }
    var method: HTTPMethod { get }
    var scheme: Scheme { get }
    var host: String? { get }
    var port: Int? { get }
    var headers: [String: String] { get }
    var queryItems: [URLQueryItem]? { get }
    var body: RequestBody? { get }
    var timeoutInterval: TimeInterval? { get }
    var authRequirement: AuthRequirement { get }
    var cachePolicy: CachePolicy? { get }
    var retryPolicy: RetryPolicy? { get }
    var priority: RequestPriority { get }
    var decoder: JSONDecoder { get }
}
```

#### Default Implementations:
- `scheme`: `.https`
- `host`: `nil` (inherits from `NetworkConfiguration.baseURL`)
- `port`: `nil`
- `headers`: `[:]`
- `queryItems`: `nil`
- `body`: `nil`
- `timeoutInterval`: `nil` (inherits client configuration)
- `authRequirement`: `.none`
- `cachePolicy`: `nil`
- `retryPolicy`: `nil`
- `priority`: `.normal`
- `decoder`: `JSONDecoder.networkKitDefault` (supports `.convertFromSnakeCase` and `.iso8601` date strategies)

---

### `HTTPMethod`
Strongly-typed HTTP verbs:
```swift
public enum HTTPMethod: String, Sendable, Hashable {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
    case head = "HEAD"
    case options = "OPTIONS"
    case trace = "TRACE"
    case connect = "CONNECT"
}
```

---

### `RequestBody`
Encapsulates payload serialization:
```swift
public enum RequestBody: Sendable {
    case data(Data, contentType: String)
    case json(Encodable & Sendable, encoder: JSONEncoder = .networkKitDefault)
    case urlEncoded([String: String])
    case multipart(MultipartFormData)
}
```

---

### `NetworkError`
Comprehensive, typed error hierarchy:
```swift
public enum NetworkError: Error, Sendable, Equatable {
    case invalidURL(String)
    case encodingFailed(String)
    case decodingFailed(EndpointDecodingFailure)
    case transportError(underlying: SendableErrorBox)
    case httpError(statusCode: Int, data: Data?, context: ResponseContext)
    case unauthorized(reason: String?)
    case cancelled
    case timedOut
    case offline
    case sslPinningFailed(host: String)
    case rateLimited(retryAfter: TimeInterval?)
    case custom(String)
}
```

---

## Module M1: Request Pipeline & Transport Layer

### `NetworkClient`
The primary entry point for executing network operations.

```swift
public final class NetworkClient: Sendable {
    public init(
        configuration: NetworkConfiguration,
        transport: NetworkTransport = URLSessionTransport(),
        tokenManager: TokenManager? = nil,
        metricsCollector: MetricsCollector? = nil
    )

    // Primary async execution
    public func request<E: Endpoint>(_ endpoint: E) async throws -> E.Response

    // Raw response execution (access HTTP headers, status code, raw data)
    public func rawRequest<E: Endpoint>(_ endpoint: E) async throws -> (data: Data, response: HTTPURLResponse)

    // Completion-handler bridge for legacy call sites
    public func request<E: Endpoint>(
        _ endpoint: E,
        completion: @escaping @Sendable (Result<E.Response, NetworkError>) -> Void
    ) -> NetworkCancellable
}
```

### `NetworkTransport` Protocol
```swift
public protocol NetworkTransport: Sendable {
    func send(request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
```

---

## Module M2: Authentication & Token Management

### `TokenManager` Actor
Thread-safe token manager that deduplicates concurrent 401 refresh requests into a single in-flight task.

```swift
public actor TokenManager {
    public init(
        storage: TokenStorage = KeychainTokenStorage(),
        refreshHandler: @escaping @Sendable (String) async throws -> TokenPair
    )

    public func validAccessToken() async throws -> String
    public func refreshToken() async throws -> String
    public func store(tokenPair: TokenPair) async throws
    public func clearTokens() async throws
}
```

### `AuthStrategy` Protocol & Built-in Strategies
```swift
public protocol AuthStrategy: Sendable {
    func apply(to request: inout URLRequest) async throws
}

public struct BearerAuth: AuthStrategy {
    public init(tokenProvider: @escaping @Sendable () async throws -> String)
}

public struct APIKeyAuth: AuthStrategy {
    public init(key: String, headerName: String = "X-API-Key")
}

public struct BasicAuth: AuthStrategy {
    public init(username: String, password: String)
}
```

---

## Module M3: Resiliency, Retry & Exponential Backoff

### `RetryPolicy`
Configurable retry behaviors with automatic `Retry-After` compliance:

```swift
public struct RetryPolicy: Sendable {
    public var maxRetries: Int
    public var backoff: ExponentialBackoff
    public var retryableStatusCodes: Set<Int>
    public var retryOnNetworkError: Bool

    public static let standard: RetryPolicy
    public static let aggressive: RetryPolicy
    public static let none: RetryPolicy
}
```

### `ExponentialBackoff`
```swift
public struct ExponentialBackoff: Sendable {
    public var initialDelay: TimeInterval
    public var maxDelay: TimeInterval
    public var multiplier: Double
    public var jitter: JitterStrategy

    public func delay(forAttempt attempt: Int) -> TimeInterval
}

public enum JitterStrategy: Sendable {
    case none
    case full
    case equal
}
```

---

## Module M4: Observability, Interceptors & Redacting Logger

### `RequestInterceptor` & `ResponseInterceptor`
```swift
public protocol RequestInterceptor: Sendable {
    func intercept(request: URLRequest) async throws -> URLRequest
}

public protocol ResponseInterceptor: Sendable {
    func intercept(response: HTTPURLResponse, data: Data) async throws -> (HTTPURLResponse, Data)
}
```

### `RedactingLogger`
Structured logging with regex-driven redaction for tokens, passwords, credit card numbers, and authorization headers:

```swift
public struct RedactingLogger: Sendable {
    public init(
        rules: [RedactionRule] = RedactionRule.standardRules,
        logLevel: LogLevel = .debug,
        printer: @escaping @Sendable (String) -> Void = { print($0) }
    )

    public func log(request: URLRequest)
    public func log(response: HTTPURLResponse, data: Data?, duration: TimeInterval)
}
```

---

## Module M5: Security & SPKI Certificate Pinning

### `SPKIPinningDelegate`
Public Key (Subject Public Key Info) SHA-256 hash validation preventing certificate expiration lockouts while protecting against MitM attacks.

```swift
public final class SPKIPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable {
    public init(pinnedHashes: [String: Set<String>]) // [Host: Set<Base64_SHA256_Hashes>]
}

public struct SSLPinningConfiguration: Sendable {
    public var pinnedHashes: [String: Set<String>]
    public var allowBackupKeys: Bool
}
```

---

## Module M6: Connectivity & Network Reachability

### `NetworkMonitor` Protocol & `PathNetworkMonitor`
```swift
public protocol NetworkMonitor: Sendable {
    var status: NetworkStatus { get }
    var statusStream: AsyncStream<NetworkStatus> { get }
}

public struct NetworkStatus: Sendable, Equatable {
    public var isConnected: Bool
    public var connectionType: ConnectionType
    public var isExpensive: Bool
    public var isConstrained: Bool
}

public enum ConnectionType: Sendable {
    case wifi, cellular, wiredEthernet, loopback, other, none
}
```

---

## Module M7: Multipart Form, Upload & Download Progress

### `MultipartFormData`
Streaming-friendly multipart body builder:
```swift
public struct MultipartFormData: Sendable {
    public mutating func append(value: String, name: String)
    public mutating func append(fileData: Data, name: String, fileName: String, mimeType: String)
    public func build() -> (data: Data, boundary: String)
}
```

### Progress Streaming Extensions
```swift
extension NetworkClient {
    public func upload<E: Endpoint>(
        _ endpoint: E,
        from fileURL: URL
    ) -> AsyncThrowingStream<ProgressEvent<E.Response>, Error>

    public func download(
        from url: URL,
        to destination: URL
    ) -> AsyncThrowingStream<DownloadProgressEvent, Error>
}

public struct ProgressEvent<T: Sendable>: Sendable {
    public var fractionCompleted: Double
    public var bytesTransferred: Int64
    public var totalBytes: Int64
    public var result: T?
}
```

---

## Module M8: Policy-Driven HTTP Response Caching

### `CachePolicy`
```swift
public enum CachePolicy: Sendable {
    case returnCacheDataElseLoad
    case returnCacheDataDontLoad
    case reloadIgnoringLocalCacheData
    case reloadRevalidatingCacheData
}
```

### `DiskCacheStore` & `MemoryCacheStore` Actors
Two-tier cache hierarchy with SHA-256 cache-key hashing and automatic expiration pruning:
```swift
public actor DiskCacheStore: CacheStore {
    public init(storageDirectory: URL, maxSizeBytes: Int = 50_000_000, defaultTTL: TimeInterval = 300)
    public func get(key: String) async -> CachedResponse?
    public func set(_ response: CachedResponse, key: String) async
    public func remove(key: String) async
    public func removeAll() async
}
```

---

## Module M9: Request Lifecycle, Deduplication & Priority

### In-Flight Deduplication & Priority Queue
- **`RequestDeduplicator`**: Automatically coalesces concurrent, identical `GET` requests onto a single flight.
- **`PriorityTaskQueue`**: Executes high-priority requests ahead of telemetry/analytics requests.
- **`RequestRegistry`**: Enables explicit task cancellation by string `RequestID`.

```swift
public enum RequestPriority: Int, Sendable, Comparable {
    case low = 0
    case normal = 1
    case high = 2
    case urgent = 3
}
```

---

## Module M10: OAuth 2.0 PKCE Engine

### `AuthorizationCodeFlow`
Implements RFC 7636 Proof Key for Code Exchange:
```swift
public struct AuthorizationCodeFlow: Sendable {
    public init(
        clientId: String,
        authorizeURL: URL,
        tokenURL: URL,
        redirectURI: URL,
        scopes: [String]
    )

    public func makeAuthorizationURL() -> (url: URL, verifier: String, state: String)
    public func exchangeCodeForToken(
        code: String,
        codeVerifier: String,
        state: String,
        expectedState: String
    ) async throws -> TokenPair
}
```

---

## Module M11: Persisted Offline Request Queue

### `OfflineRequestQueue` Actor
Persists non-idempotent write requests (e.g. `POST`, `PUT`, `DELETE`) to disk when offline, and replays them sequentially with topological integrity upon network reconnection.

```swift
public actor OfflineRequestQueue {
    public init(
        store: OfflineStore = FileOfflineStore(),
        client: NetworkClient,
        monitor: NetworkMonitor
    )

    public func enqueue<E: Endpoint>(_ endpoint: E) async throws -> UUID
    public func startAutoReplay() async
    public func stopAutoReplay() async
    public func pendingRequests() async -> [QueuedRequest]
}
```

---

## Module M12: AsyncSequence Pagination & Parallel Batching

### `PaginatedEndpoint` & AsyncSequence
```swift
public protocol PaginatedEndpoint: Endpoint {
    associatedtype Item: Decodable & Sendable
    func nextEndpoint(after currentResponse: Response) -> Self?
}

extension NetworkClient {
    public func paginate<E: PaginatedEndpoint>(
        _ endpoint: E
    ) -> AsyncThrowingStream<[E.Item], Error>

    public func batch<E: Endpoint>(
        _ endpoints: [E],
        maxConcurrent: Int = 4
    ) async -> [Result<E.Response, NetworkError>]
}
```

---

## Module M13: Test Doubles, Stubs & Mock Scenarios

### `MockNetworkTransport`
Deterministic unit testing double without making network socket connections:

```swift
public final class MockNetworkTransport: NetworkTransport, @unchecked Sendable {
    public init()
    public func registerStub<E: Endpoint>(for endpoint: E.Type, result: Result<E.Response, NetworkError>)
    public func registerRawStub(matcher: @escaping @Sendable (URLRequest) -> Bool, statusCode: Int, data: Data)
    public var recordedRequests: [URLRequest] { get }
}
```

---

## Module M14: Combine Publishers & SwiftUI @Observable

### Combine Adapter (`#if canImport(Combine)`)
```swift
extension NetworkClient {
    public func publisher<E: Endpoint>(for endpoint: E) -> AnyPublisher<E.Response, NetworkError>
    public func uploadPublisher<E: Endpoint>(_ endpoint: E, from fileURL: URL) -> AnyPublisher<ProgressEvent<E.Response>, Error>
}
```

### SwiftUI `@Observable` Adapter (`#if canImport(Observation)`)
```swift
@Observable
@MainActor
public final class NetworkResource<Value: Sendable> {
    public private(set) var state: LoadState<Value> = .idle

    public init(client: NetworkClient)
    public func load<E: Endpoint>(_ endpoint: E) async where E.Response == Value
    public func refresh<E: Endpoint>(_ endpoint: E) async where E.Response == Value
}

public enum LoadState<Value: Sendable>: Sendable {
    case idle
    case loading
    case success(Value)
    case failure(NetworkError)
}
```

---

## Summary Matrix

| Milestone | Key Capability | Primary Types | Concurrency Isolation |
|---|---|---|---|
| **M0** | Core DSL | `Endpoint`, `HTTPMethod`, `RequestBody`, `NetworkError` | Value types (`Sendable`) |
| **M1** | Transport Pipeline | `NetworkClient`, `URLSessionTransport` | Structured Concurrency |
| **M2** | Auth & Token Refresh | `TokenManager`, `BearerAuth`, `KeychainTokenStorage` | `actor TokenManager` |
| **M3** | Retry & Backoff | `RetryPolicy`, `ExponentialBackoff`, `JitterStrategy` | Pure Functions (`Sendable`) |
| **M4** | Observability | `RedactingLogger`, `RequestInterceptor`, `MetricsCollector` | `@TaskLocal TraceContext` |
| **M5** | TLS Security | `SPKIPinningDelegate`, `SSLPinningConfiguration` | Thread-safe Delegate |
| **M6** | Reachability | `PathNetworkMonitor`, `NetworkStatus` | `AsyncStream` Bridge |
| **M7** | Streaming & Progress | `MultipartFormData`, `ProgressEvent` | `AsyncThrowingStream` |
| **M8** | Response Caching | `DiskCacheStore`, `MemoryCacheStore`, `CachePolicy` | `actor DiskCacheStore` |
| **M9** | Priority & Dedup | `RequestDeduplicator`, `PriorityTaskQueue`, `RequestRegistry` | `actor RequestDeduplicator` |
| **M10** | OAuth 2.0 PKCE | `AuthorizationCodeFlow`, `PKCEChallenge` | CryptoKit SHA-256 |
| **M11** | Offline Queue | `OfflineRequestQueue`, `FileOfflineStore` | `actor OfflineRequestQueue` |
| **M12** | Pagination & Batch | `PaginatedEndpoint`, `ParallelBatchRunner` | `TaskGroup` + `AsyncSequence` |
| **M13** | Test Doubles | `MockNetworkTransport`, `MockURLProtocol` | In-memory Mock State |
| **M14** | Combine & SwiftUI | `NetworkResource`, `LoadState`, Combine Publishers | `@MainActor @Observable` |

---

*Copyright © 2026 Husnain Ali. Released under Source-available proprietary terms.*
