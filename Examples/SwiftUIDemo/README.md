# SwiftUIDemo

A complete, standalone SwiftUI app that integrates **SwiftNetworkKit**, built with **MVVM + Clean
Architecture**. Its own SwiftPM package with a local path dependency (`.package(path: "../..")`).

Three tabs against `https://jsonplaceholder.typicode.com`:

| Tab | Shows |
|---|---|
| **Users** | searchable list, pull-to-refresh, error state with retry → user detail (contact + posts + todos + albums, three parallel requests) |
| **Compose** | a form that `POST`s a JSON body and decodes the created `Post` |
| **Diagnostics** | the live client configuration + a narrated **401 → refresh → retry** walkthrough (mock transport) |

## Run

```bash
# command line (macOS)
swift run --package-path Examples/SwiftUIDemo SwiftUIDemo
```

**Xcode:** File ▸ Open… → select the `Examples/SwiftUIDemo` folder. If it reports a missing package
product, File ▸ Packages ▸ Reset Package Caches, then Resolve Package Versions.

## Architecture

```
Presentation  ──depends on──▶  Domain  ◀──implements──  Data
(SwiftUI Views + @Observable       (entities +          (Endpoints + repositories
 ViewModels)                        repository ports)    backed by NetworkClient)
                                        ▲
                          AppContainer (composition root, injected via Environment)
```

| Layer | Files | Rule |
|---|---|---|
| **Domain** | `Domain/Domain.swift` | entities + `UsersRepository` / `UserContentRepository` / `PostComposer` / `NetworkDiagnostics` protocols. **No import of SwiftNetworkKit or SwiftUI.** |
| **Data** | `Data/Endpoints.swift`, `Data/LiveRepositories.swift`, `Data/LiveDiagnostics.swift`, `Data/AppContainer.swift` | the *only* code that imports SwiftNetworkKit and calls `client.request(...)`. Implements the Domain ports. |
| **Presentation** | `Presentation/**` | `@MainActor @Observable` view models depend only on Domain protocols; SwiftUI views are dumb and bind to a view model. **No import of SwiftNetworkKit** (except `NetworkError` for display). |
| **Composition root** | `Data/AppContainer.swift` + `App/` | builds the `NetworkClient` once, wires concrete repositories, injects `AppContainer` through the SwiftUI environment. Swap `.live` for a stub in tests/previews. |

Each screen is a `ViewModel` + `View` pair. View models expose a `LoadPhase<Value>` (`idle` /
`loading` / `loaded` / `failed(NetworkError)`) and intent methods (`load()`, `submit()`); views
render it with the shared `PhaseView` / `ErrorStateView`.

To reuse in a real iOS app: drop `Domain/`, `Data/`, `Presentation/` into your target and add
SwiftNetworkKit as a package dependency.
