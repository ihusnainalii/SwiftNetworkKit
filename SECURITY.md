# Security Policy

## Reporting a vulnerability

Please do not open a public issue for security problems. Use GitHub's
[private vulnerability reporting](https://github.com/ihusnainalii/SwiftNetworkKit/security/advisories/new)
(Security tab -> Report a vulnerability), or email the maintainer.

You can expect an acknowledgement within a few days and a fix or mitigation plan for confirmed
issues before any public disclosure.

## Supported versions

Pre-1.0: only the latest tagged release is supported. Once `1.0.0` ships, the latest minor of the
current major will receive security fixes.

## Security posture of this package

SwiftNetworkKit is a client networking layer with **no external dependencies**. It does not run a
server, open listening sockets, execute downloaded code, or persist anything outside the locations
you configure.

### Cryptography

| Concern | What the package does |
|---|---|
| Hashing | SHA-256 only, via `CryptoKit` (PKCE `code_challenge`, SPKI pinning digests). No MD5 / SHA-1. |
| Ciphers | None implemented. TLS is handled by `URLSession` / the OS. No MD5 / DES / RC4 / ECB anywhere. |
| Randomness | PKCE verifiers use `SecRandomCopyBytes` (CSPRNG); OAuth `state` and trace IDs use `SystemRandomNumberGenerator`, which is CSPRNG-backed on Apple platforms. |
| TLS | System defaults (TLS 1.2 minimum). No App Transport Security exceptions, no `allowsArbitraryLoads`. |
| Certificate pinning | Opt-in (`NetworkConfiguration.sslPinning`). Runs the system chain evaluation (`SecTrustEvaluateWithError`) first, then pin matching. On mismatch the request fails with `NetworkError.sslPinningFailed(host:)`; it never falls back to "allow". `.development` / `.recordOnly` modes are explicitly non-blocking and log the values to adopt. |

### Credential handling

- Tokens live in a `TokenStorage`. `KeychainTokenStorage` defaults to
  `kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly` (device-only, not synced to iCloud).
- The redacting logger (`Redactor`) strips `Authorization`, `Cookie`, `Set-Cookie`, and common
  token-bearing headers/fields. Access and refresh tokens are never written to the log at any
  `LogLevel`.
- `ArchitectureTests` fails the build if a `print(` appears anywhere in the shipping library
  outside `ConsoleNetworkLogger`.

### Supply chain

- Zero third-party runtime or build dependencies (`Package.swift` has no `dependencies:`).
- CI runs a `gitleaks` secret scan on every push and pull request.
- Release artifacts are tagged and published by `release-please` from signed CI runs.

### Known non-goals

- Full background-transfer support (needs app-side `URLSessionConfiguration.background` wiring).
- Jailbreak / runtime-tampering detection.
- At-rest encryption of the disk cache and the offline queue: both write with iOS Data Protection
  (`.completeFileProtectionUnlessOpen`), so entries are encrypted at rest and unreadable while the
  device is locked. That is file-level protection, not app-level encryption; for genuinely
  sensitive payloads prefer Keychain or an encrypted container, and keep responses with
  `Cache-Control: no-store` out of the cache (the package already honors that).
