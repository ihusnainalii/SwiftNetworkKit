import Foundation

/// The default ``NetworkMetrics``: discards every event. No actor hop, no allocation.
public struct NoopMetrics: NetworkMetrics {
    public init() {}
    public func record(_ event: MetricEvent) async {}
}
