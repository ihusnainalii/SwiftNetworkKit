# Defining endpoints

One conforming type per API operation. Required members are minimal; the rest tune behaviour.

## Overview

``Endpoint`` is the seam between your API and the client. The package ships no app-specific
types, so you describe each operation as a value type. Keep them small and `Sendable`.

```swift
struct SearchUsers: Endpoint {
    typealias Response = Page<User>
    var path: String { "/users" }
    var queryParameters: QueryParameters? {
        var q = QueryParameters()
        q.append("q", .string(term))
        q.append("page", .int(page))
        return q
    }
    let term: String
    let page: Int
}
```

## Members

| Member | Default | Purpose |
|---|---|---|
| ``Endpoint/Response`` | (required) | the decoded type (required) |
| ``Endpoint/path`` | (required) | path appended to the environment base URL (required) |
| ``Endpoint/baseURL`` | `nil` | override the base URL for this call only |
| ``Endpoint/method`` | `.get` | ``HTTPMethod`` |
| ``Endpoint/headers`` | `[:]` | per-request headers (win over environment headers) |
| ``Endpoint/queryParameters`` | `nil` | ``QueryParameters`` (repeated keys, arrays) |
| ``Endpoint/pathParameters`` | `[:]` | `:name` tokens in `path`, encoded to a single segment |
| ``Endpoint/body`` | `nil` | ``RequestBody`` (`.json`, `.data`, `.formURLEncoded`, `.multipart`) |
| ``Endpoint/authentication`` | `.none` | `.required` attaches the token; `.none` skips auth |
| ``Endpoint/timeout`` | `nil` | override the environment timeout |
| ``Endpoint/priority`` | `.normal` | ``RequestPriority`` for the bounded queue |
| ``Endpoint/retryPolicy`` | `nil` | override the client ``RetryPolicy`` for this call |
| ``Endpoint/cachePolicy`` | `nil` | override the client ``CachePolicy`` (see <doc:Caching>) |
| ``Endpoint/deduplicate`` | `nil` | opt this call in/out of in-flight deduplication |
| ``Endpoint/offlineBehavior`` | `.fail` | `.queue` persists the request when offline (see <doc:OfflineQueue>) |
| ``Endpoint/decoder`` | `nil` | a `JSONDecoder` just for this endpoint |

## Decoding

The default ``Endpoint/decode(_:response:using:)`` runs `JSONDecoder`. Override it for
non-JSON payloads, envelopes, or an empty body:

```swift
struct DeleteUser: Endpoint {
    typealias Response = EmptyResponse   // any 2xx with no useful body
    var path: String { "/users/\(id)" }
    var method: HTTPMethod { .delete }
    let id: String
}
```

## Path parameters

`:token` segments are substituted and percent-encoded so a value can never break out of its
segment:

```swift
struct GetOrder: Endpoint {
    typealias Response = Order
    var path: String { "/orders/:id" }
    var pathParameters: [String: String] { ["id": id] }
    let id: String              // "../admin" stays one opaque segment
}
```
