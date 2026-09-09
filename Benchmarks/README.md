# Benchmarks

`results.json` is produced by the `NetworkKitBenchmarks` executable
(`Sources/NetworkKitBenchmarks/`). Each scenario drives the real package through its
own `MockNetworkTransport`, so the numbers are SwiftNetworkKit's own overhead with
the network removed.

```bash
swift run -c release NetworkKitBenchmarks --out Benchmarks/results.json
```

The Release workflow regenerates this on every tag and attaches `benchmarks.json` to
the GitHub Release; the marketing site reads that asset (falling back to this file).
Machine-dependent; treat the committed copy as a reference snapshot, not a contract.
