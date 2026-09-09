# Certificate and public-key pinning

Zero-dependency SPKI SHA-256 pinning, additive to the system's own TLS validation.

## Overview

Pinning is opt-in via ``NetworkConfiguration`` `sslPinning` (default `.disabled`). When
enabled, the transport runs `SecTrustEvaluateWithError` (full chain, hostname, expiry) **and
then** matches the server's Subject Public Key Info against your pins. Pinning never replaces
system validation, and enabling it for one host does not affect any other host.

```swift
var config = NetworkConfiguration(baseURL: "https://api.acme.com")
config.sslPinning = .publicKeys([
    "api.acme.com": ["sha256/AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=",
                     "sha256/BBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBBB="]
])
```

## Getting the pin values

Run the client in `.development` mode once. It does not enforce anything; it logs the
observed `sha256/...` values for you to paste into production.

```swift
config.sslPinning = .development(hosts: ["api.acme.com"])
// console: sha256/AAAA...  <- copy this into .publicKeys([...])
```

## Rotation

List **two** pins per host: the current key and the next one. When you rotate the server
certificate, clients that shipped with both keep working; drop the retired pin in the
following release.

## What a mismatch does

``ServerTrustEvaluator`` returns a ``ServerTrustDecision``:

| Decision | Transport answers | Result |
|---|---|---|
| `.pinned` | `.useCredential` | connection proceeds |
| `.notPinned` | `.performDefaultHandling` | host not covered by any pin, normal system TLS |
| `.rejected` | `.cancelAuthenticationChallenge` | request throws ``NetworkError/sslPinningFailed(host:)`` |

An empty pin list under enforced mode is a `precondition` failure, not "allow all".
