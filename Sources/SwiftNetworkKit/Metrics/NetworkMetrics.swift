import Foundation

/// Observability hook. `NetworkClient` `await`s one call per pipeline event; implementations must be
/// cheap and non-throwing.
///
/// Default: ``NoopMetrics``. Built-in aggregator: ``InMemoryMetrics``.
public protocol NetworkMetrics: Sendable {
    func record(_ event: MetricEvent) async
}
