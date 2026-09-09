# Authentication

Attach credentials, store tokens, and refresh a `401` once, transparently.

## Strategies

``AuthStrategy`` decides how a credential is applied to a request. Set it on
``NetworkConfiguration``.

| Strategy | Applies |
|---|---|
| ``BearerAuth`` | `Authorization: Bearer <access token>` (default) |
| ``BasicAuth`` | `Authorization: Basic <base64(user:pass)>` |
| ``APIKeyAuth`` | a key in a header or query item |
| ``CustomAuth`` | your closure |

An endpoint opts in with `var authentication: AuthRequirement { .required }`. `.none`
endpoints are sent unauthenticated even on an authenticated client.

## Token storage

``TokenStorage`` is where the ``TokenPair`` lives.

| Store | Use |
|---|---|
| ``KeychainTokenStorage`` | production. Defaults to `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`, never iCloud-synced. |
| ``InMemoryTokenStorage`` | tests, or a session that should not persist |
| your own | conform to ``TokenStorage`` |

```swift
let config = NetworkConfiguration(
    baseURL: "https://api.example.com",
    tokenStorage: KeychainTokenStorage(service: "com.acme.app")
)
```

## Automatic refresh

Pass a `refresh` handler to ``NetworkClient/init(configuration:transport:refresh:onSessionExpired:)``.
On a `401`, ``TokenManager`` (an actor) runs the handler **once** even if many requests
fail concurrently; the others await the same refresh, then all retry with the new token.

```swift
let client = NetworkClient(
    configuration: config,
    refresh: { storage in
        let refreshToken = try await storage.refreshToken()
        return try await myBackend.exchange(refreshToken)   // returns a TokenPair
    },
    onSessionExpired: {
        await AppRouter.shared.logOut()   // called once if refresh fails or a request 401s twice
    }
)
```

A request that 401s, refreshes, and succeeds on retry looks like a single successful call to
the caller. If the refresh itself fails, the request throws ``NetworkError/sessionExpired``
and `onSessionExpired` fires.

## Proactive refresh

Set ``NetworkConfiguration`` `proactiveRefreshLeeway` (default 60s) to refresh a token that
is about to expire *before* sending, avoiding the 401 round trip.

## OAuth 2.0

For the Authorization Code flow with PKCE, see <doc:OAuth>.
