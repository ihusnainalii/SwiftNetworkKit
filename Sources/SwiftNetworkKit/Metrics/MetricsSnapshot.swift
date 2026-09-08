import Foundation

/// An immutable readout of everything ``InMemoryMetrics`` has aggregated so far.
public struct MetricsSnapshot: Sendable, Equatable {
    public var requestCount: Int
    public var successCount: Int
    public var failureCount: Int
    public var retryCount: Int
    public var timeoutCount: Int
    public var tokenRefreshCount: Int
    /// Successful token refreshes only (subset of ``tokenRefreshCount``).
    public var tokenRefreshSuccessCount: Int
    /// HTTP status code -> number of completed requests (success or failure) that ended with it.
    public var statusCodeHistogram: [Int: Int]
    public var averageDuration: Duration
    public var p95Duration: Duration

    public static let empty = MetricsSnapshot(
        requestCount: 0, successCount: 0, failureCount: 0, retryCount: 0, timeoutCount: 0,
        tokenRefreshCount: 0, tokenRefreshSuccessCount: 0, statusCodeHistogram: [:],
        averageDuration: .zero, p95Duration: .zero
    )
}
