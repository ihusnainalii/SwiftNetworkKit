# Getting started

Add the package, compose a client, describe one endpoint, make a request.

## Add the dependency

```swift
.package(url: "https://github.com/ihusnainalii/SwiftNetworkKit", from: "1.0.0")
```

Then add `"SwiftNetworkKit"` to your target's dependencies.

## Compose a client

``NetworkClient`` is the single public entry point. Configure it once and share it.

```swift
let client = NetworkClient(
    configuration: NetworkConfiguration(baseURL: "https://api.example.com")
)
```

For an authenticated API, supply token storage and a refresh handler. The client then
attaches the bearer token and performs a single-flight refresh on a `401` (see
<doc:Authentication>).

```swift
let client = NetworkClient(
    configuration: NetworkConfiguration(
        baseURL: "https://api.example.com",
        tokenStorage: KeychainTokenStorage(service: "com.acme.app")
    ),
    refresh: { storage in try await exchangeRefreshToken(storage.refreshToken()) }
)
```

## Describe an endpoint

Conform a value type to ``Endpoint``. Only ``Endpoint/path`` and the associated
``Endpoint/Response`` are required; everything else has a default.

```swift
struct GetProfile: Endpoint {
    typealias Response = User
    var path: String { "/me" }
    var authentication: AuthRequirement { .required }
}

struct CreatePost: Endpoint {
    typealias Response = Post
    var path: String { "/posts" }
    var method: HTTPMethod { .post }
    var body: RequestBody? { .json(draft) }
    let draft: PostDraft
}
```

## Make requests

```swift
let user = try await client.request(GetProfile())
let post = try await client.request(CreatePost(draft: draft))
```

A completion-handler overload is available for call sites that are not `async`:

```swift
client.request(GetProfile()) { result in
    switch result {
    case .success(let user): ...
    case .failure(let error): ...   // error is a NetworkError
    }
}
```

## Next

- <doc:DefiningEndpoints> - every overridable member
- <doc:Authentication> - token storage, strategies, automatic refresh
- <doc:ErrorHandling> - the ``NetworkError`` tree
- <doc:Testing> - the shipped test doubles
