# Security Audit

_Last run: 2026-09-09. Method: manual source review of `Sources/SwiftNetworkKit` against a
cryptographic-audit checklist (weak primitives, cipher modes, key sizes, hardcoded secrets, KDF
parameters, RNG, deprecated protocols), a secret scan, and a review of the trust, credential, and
at-rest storage paths._

## Verdict

**No critical, high, or medium findings.** The package uses only modern primitives, ships no
secrets, does not weaken TLS, and defaults its credential and at-rest stores to the secure option.
Two low-severity hardening items were fixed during the audit; three residual notes are documented
for awareness.

| Severity | Count |
|---|---|
| Critical | 0 |
| High | 0 |
| Medium | 0 |
| Low (fixed) | 2 |
| Informational / by-design | 3 |

## Cryptographic review

| Check | Result |
|---|---|
| Weak hashes (MD5, SHA-1) | None. Only SHA-256, via `CryptoKit.SHA256` (PKCE `code_challenge`, SPKI pinning digests). |
| Weak ciphers (DES, 3DES, RC4, Blowfish) | None. The package implements no symmetric crypto; transport encryption is `URLSession` / OS TLS. |
| Insecure cipher modes (ECB) | Not applicable (no cipher use). |
| Key sizes | SPKI pinning supports RSA-2048 / 4096 and EC P-256 / P-384 headers. No sub-2048 RSA path. |
| KDF parameters | Not applicable. No password-based key derivation. PKCE is a challenge transform (`base64url(SHA256(verifier))`) per RFC 7636, not a KDF. |
| RNG | PKCE `code_verifier`: `SecRandomCopyBytes(kSecRandomDefault, ...)` (CSPRNG). Fallback plus OAuth `state` and trace IDs: `SystemRandomNumberGenerator`, which is CSPRNG-backed on Apple platforms. No `srand` / `drand48` / time-seeded RNG. |
| Deprecated TLS (SSLv3, TLS 1.0 / 1.1) | Not selectable. No protocol-version downgrade; `URLSession` default (TLS 1.2 floor) applies. |
| App Transport Security | No `NSAllowsArbitraryLoads`, no ATS exception dictionary, no `Info.plist` in the library. |

## Trust evaluation (certificate pinning)

- Pinning is opt-in (`NetworkConfiguration.sslPinning`, default `.disabled`).
- When enabled, the evaluator runs `SecTrustEvaluateWithError` (full system chain validation)
  before pin matching. Pinning is additive, never a replacement for chain validation.
- On pin mismatch or a missing `serverTrust`, the delegate calls `.cancelAuthenticationChallenge`
  and records `NetworkError.sslPinningFailed(host:)`. No code path accepts an unverified server on
  failure.
- `.development(...)` / `PinningMode.recordOnly` are explicitly non-blocking and only log the
  observed `sha256/...` values. The names make the trade-off obvious at the call site.
- An empty pin set under enforced mode triggers a `precondition` (fails fast rather than silently
  allowing all).

## Credential handling

| Item | Finding |
|---|---|
| Keychain accessibility default | `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`: device-only, not iCloud-synced, survives backgrounding. The most conservative sensible default. |
| Keychain sync | `kSecAttrSynchronizable` is never set true. |
| Token logging | `Redactor` always redacts `authorization`, `proxy-authorization`, `cookie`, `set-cookie`; callers add more. Bodies that do not parse as JSON are reduced to a byte-count summary. No `LogLevel` prints a raw token. |
| `print()` in the library | Forbidden and enforced: `ArchitectureTests` fails the build on any `print(` outside `ConsoleNetworkLogger`. |
| Secrets in the repo | Clean. The only matches are placeholder tokens in the CLI demo and two `Fixtures/*.der` files, which are DER-encoded public certificates for pinning tests. A `gitleaks` job with a matching allowlist runs in CI and weekly. |

## At-rest storage

| Store | Before | After (fixed) |
|---|---|---|
| `DiskCacheStore` | `data.write(to:, options: .atomic)` | `[.atomic, .completeFileProtectionUnlessOpen]`: encrypted at rest, unreadable while locked |
| `FileOfflineStore` | `...write(to:, options: .atomic)` | `[.atomic, .completeFileProtectionUnlessOpen]` |

`Cache-Control: no-store` responses are already never persisted.

## Injection / unsafe execution

| Vector | Finding |
|---|---|
| Command execution | No `Process`, `NSTask`, `system()`, `dlopen`, or `NSClassFromString`-driven dispatch. |
| URL construction | `RequestBuilder` uses `URLComponents` with proper percent-encoding for query and path parameters; no string interpolation into URLs. |
| Deserialization | `NSKeyedUnarchiver.unarchivedObject(ofClass: NSURLRequest.self, from:)` (secure coding, single expected class). No `unarchiveTopLevelObjectWithData`. |
| Response decoding | `JSONDecoder` only; no `PropertyListDecoder` or `NSKeyedUnarchiver` on response bodies. |

## Residual notes (by design, not defects)

1. `preconditionFailure` on malformed configuration URLs (`baseURL`, `authorizationEndpoint`).
   These crash on a programmer-supplied invalid URL rather than surfacing an error. A caller cannot
   reach them with attacker-controlled input. Throwing initializers are a candidate for 1.0.
2. `fatalError` if SHA-256 is unavailable (`PKCE`). Only reachable on a platform with neither
   `CryptoKit` nor `CommonCrypto`, which does not exist among the supported platforms.
3. At-rest protection is file-level, not application-level. `.completeFileProtectionUnlessOpen`
   relies on the OS passcode and Secure Enclave. For payloads that must resist a fully compromised
   unlocked device, use Keychain or an app-managed encrypted container.

## CI enforcement

On every push and pull request (and weekly):

- `gitleaks` secret scan over full history (`.github/workflows/gitleaks.yml`).
- SwiftLint `--strict` with `force_cast` / `force_try` as errors (documented, guarded exceptions
  only).
- `swift test --sanitize=thread` and `--sanitize=address`.

Re-run this audit when adding any symmetric crypto, a new persistence store, a new external-input
parser, or a change to the trust-evaluation path.
