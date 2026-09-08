# SwiftUIDemo

A complete, standalone SwiftUI **app** (Xcode project) that integrates **SwiftNetworkKit**, built
with **MVVM + Clean Architecture**. It references the package by local path
(`XCLocalSwiftPackageReference "../.."`).

> This is a real iOS app target, not a Swift Package executable. A SwiftPM `@main App` executable
> cannot launch on iOS (no app bundle / Info.plist); it crashes with `EXC_BREAKPOINT` on
> `com.apple.uikit.eventfetch-thread`. An Xcode app target with `GENERATE_INFOPLIST_FILE = YES`
> produces a proper bundle.

Three tabs against `https://jsonplaceholder.typicode.com`:

| Tab | Shows |
|---|---|
| **Users** | searchable list, pull-to-refresh, error state with retry → user detail (contact + posts + todos + albums, three parallel requests) |
| **Compose** | a form that `POST`s a JSON body and decodes the created `Post` |
| **Diagnostics** | the live client configuration (base URL, retry policy, SSL pinning mode, headers), live **connectivity** (`PathNetworkMonitor`), live **metrics** (requests / succeeded / failed / retries / average duration from `InMemoryMetrics`), and a narrated **401 → refresh → retry** walkthrough (mock transport) |

## Run

Open **`SwiftUIDemo.xcodeproj`** in Xcode, pick the **SwiftUIDemo** scheme and an iOS Simulator
(or your device), and Run.

Command line:

```bash
xcodebuild -project Examples/SwiftUIDemo/SwiftUIDemo.xcodeproj \
  -scheme SwiftUIDemo -destination 'generic/platform=iOS Simulator' build
```

If Xcode reports a missing package: **File ▸ Packages ▸ Reset Package Caches**, then **Resolve
Package Versions**.

## Architecture

```
Presentation  ──depends on──▶  Domain  ◀──implements──  Data
(SwiftUI Views + @Observable       (entities +          (Endpoints + repositories
 ViewModels)                        repository ports)    backed by NetworkClient)
                                        ▲
                          AppContainer (composition root, injected via Environment)
```

| Layer | Folder | Rule |
|---|---|---|
| **Domain** | `SwiftUIDemo/Domain/` | entities + `UsersRepository` / `UserContentRepository` / `PostComposer` / `NetworkDiagnostics` protocols. **No import of SwiftNetworkKit or SwiftUI.** |
| **Data** | `SwiftUIDemo/Data/` | the *only* code that imports SwiftNetworkKit and calls `client.request(...)`. Implements the Domain ports. `AppContainer` is the composition root. |
| **Presentation** | `SwiftUIDemo/Presentation/` | `@MainActor @Observable` view models depend only on Domain protocols; SwiftUI views bind to a view model. **No import of SwiftNetworkKit** (except `NetworkError` for display). |
| **App** | `SwiftUIDemo/App/` | `@main App`, `RootView` (TabView), the `AppContainer` environment key. |

One file per type. Each screen is a `ViewModel` + `View` pair; view models expose a
`LoadPhase<Value>` (`idle` / `loading` / `loaded` / `failed(NetworkError)`) plus intent methods,
rendered by the shared `PhaseView` / `ErrorStateView`.

To reuse in your own app: drop `Domain/`, `Data/`, `Presentation/` into your target and add
SwiftNetworkKit as a package dependency.
