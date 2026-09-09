# Interceptors

Adapt outgoing requests and inspect responses without subclassing anything.

## Request interceptors

``RequestInterceptor`` adapts a `URLRequest` just before it is sent, after auth and tracing
have run. Register them on ``NetworkConfiguration`` `requestInterceptors`; they run in order.

```swift
struct FeatureFlags: RequestInterceptor {
    func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
        var r = request
        r.setValue(await flags.header(), forHTTPHeaderField: "X-Flags")
        return r
    }
}

config.requestInterceptors = [FeatureFlags()]
```

## Response interceptors

``ResponseInterceptor`` sees the response before status mapping and decoding. It runs in
**reverse** registration order (middleware semantics) and returns an ``InterceptOutcome``.

| ``InterceptOutcome`` | Effect |
|---|---|
| `.proceed` | carry on to status mapping and decoding |
| `.retry(after:)` | resend after a delay, capped at 2 interceptor-driven retries |
| `.fail(error)` | fail now with a ``NetworkError`` |
| `.substitute(data)` | replace the body, keep the status, proceed |

```swift
struct UnwrapEnvelope: ResponseInterceptor {
    func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
        guard let inner = try? JSONDecoder().decode(Envelope.self, from: context.data) else {
            return .proceed
        }
        return .substitute(inner.payload)
    }
}
```

## Tracing

``TracingInterceptor`` (installed automatically from ``NetworkConfiguration`` `tracing`)
attaches correlation headers so a request can be followed across services.

## Ordering

`auth → tracing → your request interceptors → transport → your response interceptors (reverse)
→ status mapping → decode`, all inside the ``RetryPolicy`` loop.
