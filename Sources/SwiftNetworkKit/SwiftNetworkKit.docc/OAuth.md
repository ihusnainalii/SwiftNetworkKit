# OAuth 2.0 with PKCE

Build the authorization URL, receive the code, exchange it for tokens. No UI is imposed.

## Overview

``AuthorizationCodeFlow`` implements RFC 6749 Authorization Code with RFC 7636 PKCE. It does
**no** presentation: you show ``AuthorizationCodeFlow/authorizationURL(state:pkce:)`` (for
example in `ASWebAuthenticationSession`), catch the redirect, and hand the code back.

## Flow

```swift
let flow = AuthorizationCodeFlow(configuration: OAuthConfiguration(
    authorizationEndpoint: URL(string: "https://id.example.com/authorize")!,
    tokenEndpoint: URL(string: "https://id.example.com/token")!,
    clientID: "acme-ios",
    redirectURI: "acme://callback",
    scopes: ["openid", "profile", "offline_access"]
))

// 1. Create a PKCE pair and CSRF state, keep them until the redirect returns.
let pkce = PKCE()
let state = UUID().uuidString

// 2. Present the authorization URL.
let url = flow.authorizationURL(state: state, pkce: pkce)

// 3. On the redirect, validate state and pull the code.
let code = try flow.authorizationCode(fromRedirect: redirectURL, expectedState: state)

// 4. Exchange the code (sends code_verifier, never the challenge).
let tokens = try await flow.exchange(code: code, pkce: pkce)   // OAuthTokenResponse
```

## PKCE

``PKCE`` generates a high-entropy `code_verifier` with a CSPRNG and derives
`code_challenge = base64url(SHA256(verifier))`. Only the challenge travels in the
authorization request; the verifier is sent once, at exchange.

## Refresh

```swift
let refreshed = try await flow.refresh(refreshToken: tokens.refreshToken)
```

Store the resulting tokens in your ``TokenStorage`` and the rest of the client (see
<doc:Authentication>) takes over.
