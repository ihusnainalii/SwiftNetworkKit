import Foundation

/// A ``NetworkMetrics`` that aggregates events in memory. Read the running totals with ``snapshot()``.
public actor InMemoryMetrics: NetworkMetrics {

    private var requestCount = 0
    private var successCount = 0
    private var failureCount = 0
    private var retryCount = 0
    private var timeoutCount = 0
    private var tokenRefreshCount = 0
    private var tokenRefreshSuccessCount = 0
    private var statusCodeHistogram: [Int: Int] = [:]
    private var durations: [Duration] = []

    public init() {}

    public func record(_ event: MetricEvent) async {
        switch event {
        case .requestStarted:
            requestCount += 1
        case .success(_, let duration, let status):
            successCount += 1
            durations.append(duration)
            statusCodeHistogram[status, default: 0] += 1
        case .failure(_, _, let status):
            failureCount += 1
            if let status { statusCodeHistogram[status, default: 0] += 1 }
        case .retry:
            retryCount += 1
        case .timeout:
            timeoutCount += 1
        case .tokenRefresh(let success):
            tokenRefreshCount += 1
            if success { tokenRefreshSuccessCount += 1 }
        }
    }

    public func snapshot() -> MetricsSnapshot {
        MetricsSnapshot(
            requestCount: requestCount,
            successCount: successCount,
            failureCount: failureCount,
            retryCount: retryCount,
            timeoutCount: timeoutCount,
            tokenRefreshCount: tokenRefreshCount,
            tokenRefreshSuccessCount: tokenRefreshSuccessCount,
            statusCodeHistogram: statusCodeHistogram,
            averageDuration: Self.average(durations),
            p95Duration: Self.percentile(durations, 0.95)
        )
    }

    /// Resets every counter.
    public func reset() {
        requestCount = 0
        successCount = 0
        failureCount = 0
        retryCount = 0
        timeoutCount = 0
        tokenRefreshCount = 0
        tokenRefreshSuccessCount = 0
        statusCodeHistogram = [:]
        durations = []
    }

    private static func average(_ values: [Duration]) -> Duration {
        guard !values.isEmpty else { return .zero }
        return values.reduce(.zero, +) / values.count
    }

    private static func percentile(_ values: [Duration], _ fraction: Double) -> Duration {
        guard !values.isEmpty else { return .zero }
        let sorted = values.sorted()
        let index = Int((Double(sorted.count - 1) * fraction).rounded())
        return sorted[index]
    }
}
