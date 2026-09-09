# Logging, redaction, and metrics

Structured, redacted logging and a pluggable metrics sink, both off the hot path.

## Log level

``NetworkEnvironment`` `logLevel` gates everything. At ``LogLevel/none`` the client does no
formatting at all.

| ``LogLevel`` | Emits |
|---|---|
| `.none` | nothing |
| `.error` | failures only |
| `.basic` | one line per request and response |
| `.verbose` | + headers and a body summary |
| `.debug` | + full redacted bodies |

## Redaction

``Redactor`` runs before any line reaches a ``NetworkLogger``. `authorization`,
`proxy-authorization`, `cookie`, and `set-cookie` are always redacted; add more headers and
JSON body keys on ``NetworkConfiguration``:

```swift
var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.redactedHeaders = ["x-api-key"]
config.redactedBodyKeys = ["password", "otp", "ssn"]
```

Bodies that are not JSON are reduced to a byte count. No log level ever prints a raw token.

## Sinks

``NetworkLogger`` is the output. The default ``ConsoleNetworkLogger`` routes to `os.Logger`
on Apple platforms and `print` elsewhere. Supply your own to forward lines to a file or a
crash reporter.

## Metrics

``NetworkMetrics`` receives a ``MetricEvent`` for each request lifecycle transition
(`requestStarted`, `success(duration:status:)`, `failure`, `retry`, `timeout`,
`tokenRefresh`). ``InMemoryMetrics`` aggregates them into a ``MetricsSnapshot`` (counts, p50 /
p90 / p95 durations, status distribution); ``NoopMetrics`` (the default) discards them.

```swift
let metrics = InMemoryMetrics()
config.metrics = metrics
// later
let snapshot = await metrics.snapshot()
```
