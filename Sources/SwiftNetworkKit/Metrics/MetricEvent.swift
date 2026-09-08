import Foundation

/// A single observable moment in a request's life. Emitted by `NetworkClient` to ``NetworkMetrics``.
public enum MetricEvent: Sendable {
    case requestStarted(RequestID)
    case success(RequestID, duration: Duration, status: Int)
    case failure(RequestID, NetworkError, status: Int?)
    case retry(RequestID, attempt: Int)
    case timeout(RequestID)
    case tokenRefresh(success: Bool)
}
