# Benchmarks

`results.json` is produced by the `NetworkKitBenchmarks` executable
(`Sources/NetworkKitBenchmarks/`). Each scenario drives the real package through its
own `MockNetworkTransport`, so the numbers are SwiftNetworkKit's own overhead with
the network removed.

```bash
swift run -c release NetworkKitBenchmarks --out Benchmarks/results.json --traces Benchmarks/traces.json
```

## What is measured

- `pipeline_overhead` and `pipeline_{1,4,16}_interceptors`: full `client.request()` cost and
  how it scales with the interceptor chain (subtract the baseline for per-interceptor cost).
  Request building and cache-key derivation are internal and are exercised inside these numbers.
- `json_decode_*`, `memory_cache_roundtrip`, `disk_cache_roundtrip`, `cache_served_request`,
  `redaction_*`, `metrics_record`: isolated component costs.
- `dedup_*`, `single_flight_refresh`: the concurrency wins.
- `traces.json`: real requests walked stage by stage (cache miss/hit, retry, 401 refresh,
  upload, download, OAuth) plus concurrent-run swimlanes.

The Release workflow regenerates this on every tag and attaches `benchmarks.json` to
the GitHub Release; the marketing site reads that asset (falling back to this file).
Machine-dependent; treat the committed copy as a reference snapshot, not a contract.
