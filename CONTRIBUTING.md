# Contributing to SwiftNetworkKit

Thanks for your interest. Please read this before opening an issue or a pull request.

## Asking questions

**Do not open a GitHub issue to ask a question.** Issues are for confirmed bugs and accepted
feature work only.

| Your question is about | Ask here |
|---|---|
| How to use a SwiftNetworkKit feature, best practices, or a design idea | [GitHub Discussions](https://github.com/ihusnainalii/SwiftNetworkKit/discussions) |
| General Swift, `URLSession`, or HTTP behavior not specific to this package | Stack Overflow, the [Swift Forums](https://forums.swift.org) |
| Whether something is a bug | Discussions first; if it is confirmed, then file an issue |

## Reporting security issues

Do **not** file a public issue for a security problem. Follow [SECURITY.md](SECURITY.md): use
GitHub's private vulnerability reporting or email the maintainer. You will get an acknowledgement
within a few days.

## Reporting bugs

Before filing:

1. Search [existing issues](https://github.com/ihusnainalii/SwiftNetworkKit/issues) and Discussions.
2. Confirm you are on the latest tagged release.
3. Reduce it to the smallest reproduction you can.

Then open an issue with the bug template and include:

- SwiftNetworkKit version, Swift/Xcode version, OS and version, device or simulator.
- What you did, what you expected, what happened.
- A minimal code sample or a failing test. A reproduction that uses `MockNetworkTransport` or
  `URLProtocolStub` is ideal because it removes the network as a variable.
- Relevant logs at `LogLevel.debug` (tokens are already redacted).

Issues without enough detail to reproduce may be closed with a request for more information.

## Requesting features

Start a thread in [Discussions](https://github.com/ihusnainalii/SwiftNetworkKit/discussions)
describing the problem you are trying to solve, not just the API you have in mind. If there is
agreement that it fits the package's scope (see [ROADMAP.md](ROADMAP.md)), open an issue with the
feature template. Features that add a dependency, or that duplicate what an interceptor or a custom
`Endpoint` can already do, are generally out of scope.

## Submitting pull requests

- **Discuss non-trivial changes first.** Anything beyond a small fix or docs change should be
  agreed in Discussions before you open a PR, or it may be closed without review.
- **Disclose AI assistance.** If you used an AI coding tool, say so in the PR description and to
  what degree. The prose of the PR description should be written by you.
- **Include tests.** Add tests for new behavior and for any bug you fix (a regression test named
  for the bug). Do not weaken existing tests to make a change pass.
- **Keep it green.** Every check in [Development loop](#development-loop) must pass locally, and the
  CI jobs must be green: build with `-warnings-as-errors`, `swift test`, ThreadSanitizer,
  AddressSanitizer, SwiftLint `--strict`, `swift format lint --strict`, iOS builds, DocC.
- **One logical change per PR.** Use [Conventional Commits](https://www.conventionalcommits.org/)
  for the title.
- **Update the docs** in the same PR: `README.md` (and its feature list), `ROADMAP.md` if scope
  changes, and doc comments with a runnable `swift` example for any new public API.
- **Wire it into a demo** (`Sources/NetworkKitDemo/` and/or `Examples/SwiftUIDemo/`) when it is a
  user-facing feature.

### Licensing of contributions

SwiftNetworkKit is source-available proprietary software owned by Husnain Ali (see
[LICENSE](LICENSE)). By submitting a pull request you **assign all right, title, and interest in
your contribution to the Owner**, as set out in Section 4 of the LICENSE, and you confirm the work
is your own and you have the right to assign it. The codebase remains solely the Owner's property.
If you are not willing to assign your contribution, open an issue or a Discussion instead of a PR.

## Development loop

```bash
swift build -Xswiftc -warnings-as-errors                                  # must be clean
swift test --parallel                                                      # all green
swift test --sanitize=thread                                                # no data races
swiftlint --strict                                                          # brew install swiftlint
swift format lint -r -s --configuration .swift-format Sources Tests
swift format format -i -r --configuration .swift-format Sources Tests       # auto-fix
bash scripts/coverage.sh                                                    # local coverage report
```

Run these from the repository root (`swiftlint` does not search parent directories for its config).

## Releases

`release-please` reads the Conventional Commit history. On every merge to `main` it maintains a
release PR that bumps `version.txt` and prepends a `CHANGELOG.md` section. Merging that PR tags the
commit (`v0.2.0`) and publishes a GitHub Release. `feat:` gives a minor bump, `fix:` / `perf:` a
patch, and `!` or `BREAKING CHANGE:` a breaking bump (pre-1.0, a breaking change is a minor bump).
Do not edit versioned `CHANGELOG.md` sections or create tags by hand.

## House style

- **Zero dependencies.** `Package.swift` must stay free of `dependencies:`.
- **One primary type per file**, grouped into folders by cluster (`Cache/`, `OAuth/`, and so on).
- **Swift 6 language mode, strict concurrency.** New public types are `Sendable`. Shared mutable
  state is an `actor`, or a lock-guarded `@unchecked Sendable` with a comment explaining the region.
- **Platform code is guarded.** Anything importing `Security`, `Network`, `CryptoKit`, `Combine`,
  `Observation`, or `os` sits behind `#if canImport(...)`.
- No `print()` in the library (use `NetworkLogger`). `ArchitectureTests` enforces this.
- Prefer `async/await` and `actor` for new code; Combine and SwiftUI helpers stay thin adapters
  over the async API.
- Line length 120 soft, 160 hard.
- Markdown docs: no em dashes or en-dash ranges; keep the README feature list a plain checklist.

## Code of conduct

Be respectful and constructive. Harassment, personal attacks, and dismissive behavior are not
welcome in issues, Discussions, or pull requests. The maintainer may edit, lock, or remove
contributions that violate this, and may block repeat offenders.
