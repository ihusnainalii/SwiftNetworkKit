# ``SwiftNetworkKit``

A composable, protocol-oriented networking layer for Swift. Zero external dependencies, Swift 6
strict concurrency.

## Overview

The public surface is one composable ``NetworkClient`` plus an ``Endpoint`` protocol each app
implements for its own API. Internally the client is assembled from small, individually-testable,
protocol-backed components — transport, auth + refresh, retry, interceptors, logging, metrics,
pinning, caching, request management, offline queue — each with a sensible default.

```swift
let client = NetworkClient(configuration: NetworkConfiguration(
    baseURL: "https://api.example.com",
    tokenStorage: KeychainTokenStorage(service: "com.acme.app")
), refresh: { storage in try await exchangeRefreshToken(storage.refreshToken()) })

struct GetProfile: Endpoint {
    typealias Response = User
    var path: String { "/me" }
    var authentication: AuthRequirement { .required }
}

let user = try await client.request(GetProfile())
```

## Topics

### Essentials

- ``NetworkClient``
- ``NetworkConfiguration``
- ``NetworkEnvironment``
- ``Endpoint``
- ``NetworkError``

### Authentication

- ``AuthStrategy``
- ``TokenStorage``
- ``TokenManager``
- ``AuthorizationCodeFlow``
- ``PKCE``

### Resilience

- ``RetryPolicy``
- ``BackoffStrategy``
- ``NetworkClock``
- ``CachePolicy``
- ``ResponseCache``
- ``OfflineBehavior``

### Observability

- ``RequestInterceptor``
- ``ResponseInterceptor``
- ``NetworkLogger``
- ``Redactor``
- ``NetworkMetrics``
- ``TracingInterceptor``

### Transfer

- ``MultipartFormData``
- ``ProgressEvent``
- ``NetworkMonitor``
- ``PaginatedEndpoint``

### Security

- ``SSLPinning``
- ``ServerTrustEvaluating``

### Testing

- ``MockNetworkTransport``
- ``MockScenario``
- ``URLProtocolStub``
- ``TestClock``
- ``CapturingLogger``
- ``MockNetworkMonitor``
- ``InMemoryOfflineStore``
