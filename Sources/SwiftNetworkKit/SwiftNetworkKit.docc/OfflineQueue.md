# Offline request queue

Persist selected requests when the device is offline and replay them on reconnect.

## Overview

Opt an endpoint in with `var offlineBehavior: OfflineBehavior { .queue(expiresAfter: 3600) }`.
The client needs an ``OfflineStore`` and a ``NetworkMonitor``:

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.offlineStore = FileOfflineStore(directory: appSupport)
config.networkMonitor = PathNetworkMonitor()
```

When such a request is made while offline it is archived and the call throws
``NetworkError/offlineQueued(_:)`` carrying a ``RequestID``. Your UI updates optimistically.

## Replay

The queue drains automatically when ``NetworkMonitor`` reports connectivity, in FIFO order.
Outcomes arrive on a stream:

```swift
for await event in await client.offlineReplayEvents() {
    switch event {
    case .replayed(let id, let statusCode): reconcile(id, statusCode)
    case .failed(let id, let error):        surface(id, error)
    case .expired(let id):                  drop(id)
    }
}
```

`client.replayOfflineQueue()` forces a drain immediately.

## Constraints

- Multipart bodies are not archived (they may reference files that move); those requests
  fall back to `.fail`.
- Bearer tokens are re-attached at replay time from current ``TokenStorage``, not stored
  with the request.
- Entries past `expiresAfter` are dropped with a `.expired` event rather than replayed.
