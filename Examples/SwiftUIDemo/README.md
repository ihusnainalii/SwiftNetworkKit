# SwiftUIDemo

A standalone SwiftUI app that integrates **SwiftNetworkKit** via a local path dependency
(`.package(name: "SwiftNetworkKit", path: "../..")`).

It lists users from `https://jsonplaceholder.typicode.com`, drills into a detail screen that loads
that user's posts, and shows idle / loading / loaded / error states with pull-to-refresh and retry.

## Run (command line — macOS)

```bash
# from this directory
swift run SwiftUIDemo

# or from the repo root
swift run --package-path Examples/SwiftUIDemo SwiftUIDemo
```

## Run in Xcode

1. In Xcode: **File ▸ Open…** and select the **`Examples/SwiftUIDemo`** folder (open the folder, not
   just `Package.swift`).
2. If you see *“Missing package product 'SwiftNetworkKit'”*: **File ▸ Packages ▸ Reset Package Caches**,
   then **File ▸ Packages ▸ Resolve Package Versions**. This happens when a stale `Package.resolved`
   is cached — the local `path: "../.."` dependency resolves fine once caches are cleared.
3. Pick the **SwiftUIDemo** scheme and a My Mac / iOS Simulator destination, then Run.

The dependency is declared as `.package(path: "../..")` — a plain local path dependency on this
repo. No `name:` argument (Xcode 26 rejects it on path dependencies).

To use it inside an existing iOS app instead, drag the four files in `Sources/SwiftUIDemo/` into your
app target and add SwiftNetworkKit as a package dependency.

## How it integrates the package

| File | What it shows |
|---|---|
| `API.swift` | `Endpoint` conformances (`ListUsers`, `PostsByUser`) + one shared pre-configured `NetworkClient` |
| `Loadable.swift` | a `@MainActor @Observable` load-state holder over `NetworkError` — the shape SwiftNetworkKit ships as `NetworkResource` in milestone M14 |
| `ContentView.swift` | `.task { await loadable.load { try await client.request(endpoint) } }`, `.refreshable`, `ContentUnavailableView` fed by `error.localizedDescription`, `navigationDestination` to a detail screen |

The app never touches `URLSession`, decoding, or error mapping — only `Endpoint` types and
`try await client.request(...)`.
