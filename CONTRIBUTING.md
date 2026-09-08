# Contributing to SwiftNetworkKit

## Ground rules

- **Zero dependencies.** `Package.swift` must stay free of `dependencies:`. If a feature seems to
  need one, it probably belongs in a companion package.
- **One primary type per file**, grouped into folders by cluster (`Cache/`, `OAuth/`, ...).
- **Swift 6 language mode, strict concurrency.** New public types are `Sendable`. Shared mutable
  state is an `actor` or a lock-guarded `@unchecked Sendable` with a comment explaining the region.
- **Platform code is guarded.** Anything importing `Security`, `Network`, `CryptoKit`, `Combine`,
  `Observation`, or `os` sits behind `#if canImport(...)`.
- No `print()` in the library (use `NetworkLogger`). `ArchitectureTests` enforces this.

## Development loop

```bash
swift build -Xswiftc -warnings-as-errors     # must be clean
swift test --parallel                         # 224 tests, all green
swift test --sanitize=thread                   # no data races
swiftlint --strict                             # brew install swiftlint
swift format lint -r -s --configuration .swift-format Sources Tests
swift format format -i -r --configuration .swift-format Sources Tests   # auto-fix
bash scripts/coverage.sh                        # local coverage report
```

CI runs all of the above plus AddressSanitizer, iOS Simulator builds (library + `SwiftUIDemo`),
a DocC build, and a `gitleaks` scan. Every job must be green.

## Commits and releases

Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/):

```
feat(cache): add stale-if-error window
fix(oauth): reject a redirect whose state does not match
docs(readme): document the offline queue
chore(ci): bump macOS runner
```

`release-please` reads this history. On every merge to `main` it maintains a **release PR** that
bumps `version.txt` and prepends a `CHANGELOG.md` section. Merging that PR tags the commit
(`v0.2.0`) and publishes a GitHub Release. `feat:` -> minor, `fix:`/`perf:` -> patch, `!` or
`BREAKING CHANGE:` -> a breaking bump. Do not edit versioned `CHANGELOG.md` sections or create
tags by hand.

## Adding a feature

1. Open an issue describing the surface area first.
2. Public API gets doc comments with a runnable `swift` example.
3. Unit tests use the shipped test doubles (`MockNetworkTransport`, `URLProtocolStub`,
   `TestClock`, and so on). No real network in tests.
4. Update `README.md` (and its feature list) and `ROADMAP.md` if the scope changes.
5. Wire the feature into a demo (`Sources/NetworkKitDemo/` and/or `Examples/SwiftUIDemo/`).

## Style specifics

- Markdown docs: no em dashes or en-dash ranges. Keep the README feature list a plain checklist.
- Line length 120 (soft), 160 (hard).
- Prefer `async/await` and `actor` for new code; Combine and SwiftUI helpers stay thin adapters
  over the async API, gated by `#if canImport`.
