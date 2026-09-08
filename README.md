# SwiftNetworkKit

A composable, protocol-oriented networking layer for Swift. Zero external dependencies.
Swift 6 strict concurrency. iOS 16+ / macOS 13+ / tvOS 16+ / watchOS 9+ / visionOS 1+.

> **Status:** in development. Milestones **M0–M2** are complete (core types, request pipeline,
> authentication + automatic token refresh). See [`.claude/PRPs/plans/swift-network-kit.plan.md`](.claude/PRPs/plans/swift-network-kit.plan.md)
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

// 3. Call it — three styles
let user: User = try await client.request(GetProfile())               // async/await
client.request(GetProfile()) { (r: Result<User, NetworkError>) in }   // completion handler
```

A `.required` endpoint that 401s triggers a single-flight token refresh and one automatic retry;
a second 401 for the same request surfaces `NetworkError.sessionExpired`.

## Demo

A runnable tour of everything shipped so far:

```bash
swift run NetworkKitDemo            # hits the live jsonplaceholder.typicode.com API
swift run NetworkKitDemo --offline  # auth + refresh section only, no network
```

Source: [`Sources/NetworkKitDemo/`](Sources/NetworkKitDemo/).

## What's implemented

| Area | Status |
|---|---|
| Generic HTTP (methods, headers, query, path params, JSON/form/raw bodies) | ✅ M0–M1 |
| `Endpoint` abstraction with per-endpoint overrides | ✅ M0 |
| Typed decoding (`Decodable` / `Data` / `String` / `EmptyResponse`) | ✅ M1 |
| `async/await` + completion-handler APIs | ✅ M1 |
| Unified `NetworkError` (+ status, headers, body, server message) | ✅ M0 |
| Auth strategies (Bearer / API key / Basic / custom) | ✅ M2 |
| `TokenStorage` (in-memory + Keychain, pluggable) | ✅ M2 |
| Actor `TokenManager` — single-flight 401 refresh, queueing, loop guard | ✅ M2 |
| Request mocking (`MockNetworkTransport`, `URLProtocolStub`) | ✅ (shipped) |
| Retry + backoff, SSL pinning, caching, upload/download, reachability, OAuth, offline, pagination, Combine/SwiftUI | ⏳ M3–M14 |

## Tests

```bash
swift test
swift test --sanitize=thread
```

## License

Apache-2.0.
