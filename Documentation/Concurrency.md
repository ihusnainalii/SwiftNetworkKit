# Concurrency & Modernity

_Scope: the shipping library target `Sources/SwiftNetworkKit` (~124 files, ~6,000 lines)._

## Headline

| Paradigm | Reach | Verdict |
|---|---|---|
| Swift 6 language mode + strict concurrency | 100% of targets | Baseline, not opt-in |
| `async/await` | Core call path, 47 files touch it | Primary API |
| Actors for shared mutable state | 13 actors | Every stateful component |
| `Sendable` correctness | 96 / 124 files annotated | Enforced by the compiler |
| Completion handlers | 8 files, thin bridge | Compatibility shim over the async core |
| Combine | 1 file (~130 lines) | Opt-in adapter, `#if canImport(Combine)` |
| SwiftUI / Observation | 2 files (~160 lines) | Opt-in adapter, iOS 17+, `#if canImport(Observation)` |

The package is async/await-and-actor-native. Combine and SwiftUI are ~290 lines total (under 5% of
the library) and are pure adapters: they call the same `async` methods everyone else does and add
no behavior. Completion handlers are a similar-sized bridge for pre-async call sites.

## Concurrency primitives

| Signal | Files | Notes |
|---|---:|---|
| `async` / `await` | 47 | Request pipeline, auth, cache, retry, upload/download, pagination, offline |
| Defines an `actor` | 13 | See list below |
| `Sendable` / `@Sendable` in the file | 96 | Public types are `Sendable`; closures crossing isolation are `@Sendable` |
| `Async(Throwing)Stream` / `AsyncSequence` | 7 | Reachability, progress, pagination, offline replay events |
| Structured concurrency (`Task` / `TaskGroup` / `withTaskCancellationHandler`) | 14 | `zip`/`batch` use `async let` + `withThrowingTaskGroup`; requests use cancellation handlers |
| Continuation bridges (`withCheckedThrowingContinuation`) | 2 | Only where `URLSession` delegates force it (upload/download progress) |
| `@unchecked Sendable` | 10 | `URLSession` delegates + test doubles; each has a lock-guarded region with a comment |
| `@MainActor` | 2 | `NetworkResource`, `Paged` (SwiftUI holders) |
| `@TaskLocal` | 1 | `TraceContext` for correlation-ID propagation |
| `#if canImport(...)` platform guards | 17 | `Security`, `Network`, `CryptoKit`, `Combine`, `Observation`, `os` |

## The 13 actors

`TokenManager` (single-flight 401 refresh), `RequestQueue` (concurrency + priority),
`RequestRegistry` (cancel-by-id), `RequestDeduplicator` (in-flight GET collapsing),
`NetworkStatusBroadcaster` (fan-out of reachability), `MemoryCacheStore`, `DiskCacheStore`,
`InMemoryMetrics`, `OfflineRequestQueue`, `PageCursor` (pagination), `InMemoryTokenStorage`,
`InMemoryOfflineStore`, plus test-only pieces.

There are **no locks used for domain state** anywhere in the library. `NSLock` appears only inside
the three `URLSession` delegate shims and the test doubles, guarding a handful of lines each,
because `URLSession`'s delegate callbacks are not `async` and land on arbitrary threads.

## Completion-handler surface (the compatibility bridge)

8 files expose an `@escaping` completion variant. Every one is a wrapper:

```swift
public func request<E: Endpoint>(
    _ endpoint: E,
    completion: @escaping @Sendable (Result<E.Response, NetworkError>) -> Void
) {
    Task { completion(await Result { try await request(endpoint) }) }
}
```

No logic is duplicated; removing the completion API would delete wrappers, not features.

## Combine layer (`Combine/`)

- `publisher(for:)`, `paginatePublisher`, `uploadPublisher`, `downloadPublisher`.
- All four are built on one `makePublisher` bridge: `Deferred { PassthroughSubject }`, work runs in
  a `Task` started on subscription, `receiveCancel` cancels the `Task`, sends are serialized
  through a locked box (progress callbacks fire off-thread).
- The entire file is inside `#if canImport(Combine)`; the package builds and works fully without it.

## SwiftUI layer (`SwiftUI/`)

- `NetworkResource<Value>` and `Paged<Item>`: `@MainActor @Observable` load-state holders.
- `@available(iOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, *)` gated, inside
  `#if canImport(Observation)`. No `ObservableObject` fallback is shipped.
- These are the only `@MainActor` types in the library.

## What "modern" means here, concretely

1. **No `DispatchQueue` for application logic.** `PathNetworkMonitor` hands `NWPathMonitor` a
   `DispatchQueue` because the API demands one, then republishes onto an `AsyncStream`. No other
   `DispatchQueue` in the library.
2. **No `Result`-based internal APIs.** `Result` appears only at the completion-handler boundary
   and in `client.batch` (where "a list of independent outcomes" is the actual return type).
3. **Cancellation is cooperative and wired through.** Cancelling the calling `Task` cancels the
   `URLSession` task via `withTaskCancellationHandler`; `paginate`'s stream `onTermination` cancels
   the driving `Task`; `NetworkResource.load` cancels the previous load.
4. **Value types by default.** Configuration, endpoints, HTTP value types, errors, policies are
   structs/enums. The reference types are the actors and the intentionally-shared `NetworkClient`.
5. **Swift Testing, not XCTest.** 224 `@Test` functions across 45 `@Suite`s.

## Where the modern story is thinnest

| Area | State | Note |
|---|---|---|
| `Transport/` delegates | `@unchecked Sendable` + `NSLock` | Unavoidable: `URLSessionDelegate` is not `async`. Regions are tiny and commented. |
| iOS 16 SwiftUI | Not covered by shipped types | `NetworkResource` / `Paged` need Observation (17+). Deliberate; documented. |
| Typed throws (`throws(NetworkError)`) | Not adopted | Would tighten the API but raises the tooling floor; revisit for 1.0. |
| Response-body streaming | Not implemented | Candidate post-1.0. |

## One-line summary

> ~95% of the library is async/await + actors + `Sendable` under Swift 6 strict concurrency;
> Combine (~130 lines) and SwiftUI (~160 lines) are optional `#if canImport` adapters over that
> core, and completion handlers are an 8-file wrapper with no independent logic.
