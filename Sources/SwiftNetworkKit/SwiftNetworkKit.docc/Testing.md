# Testing

The package ships its own test doubles so you can drive the real pipeline without a network.

## Mock transport

``MockNetworkTransport`` is a ``NetworkTransport`` you script. Inject it in place of the
default:

```swift
let transport = MockNetworkTransport(default: .json(usersJSON))
transport.stub(method: .post, pathContains: "/users", with: .status(201))
transport.stub(matching: { $0.value(forHTTPHeaderField: "Authorization") == nil },
               with: .status(401), .json(usersJSON))   // 401 then success

let client = NetworkClient(configuration: config, transport: transport)
```

Every request is recorded (`transport.recordedRequests`, `transport.requestCount`). Rules win
over the FIFO queue; each rule can hold a scripted sequence for retry / refresh tests.

Presets live in ``MockScenario``.

## Deterministic time

``TestClock`` replaces ``NetworkConfiguration`` `clock` so retry backoff advances instantly:

```swift
let clock = TestClock()
config.clock = clock
config.retry = RetryPolicy(maxAttempts: 3, backoff: .exponential(base: 1))

async let result = client.request(FlakyEndpoint())
await clock.advance(by: .seconds(3))     // fast-forward the backoff sleeps
```

## Other doubles

| Type | Replaces |
|---|---|
| ``URLProtocolStub`` | the real `URLSession` at the `URLProtocol` layer, for end-to-end transport tests |
| ``CapturingLogger`` | ``ConsoleNetworkLogger``; keeps every line for assertions |
| ``MockNetworkMonitor`` | ``NetworkMonitor``; push connectivity changes on demand |
| ``InMemoryOfflineStore`` | ``FileOfflineStore``; no disk in tests |
