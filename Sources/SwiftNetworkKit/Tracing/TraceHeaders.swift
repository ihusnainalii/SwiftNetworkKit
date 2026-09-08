import Foundation

/// Which correlation headers ``TracingInterceptor`` attaches, and under what names.
public struct TraceHeaders: Sendable, Hashable {

    /// Header carrying a fresh per-request UUID. Empty string disables it.
    public var requestIDHeader: String

    /// Header carrying the caller-supplied correlation id from ``NetworkClient/withCorrelation(_:operation:)``.
    /// Empty string disables it.
    public var correlationIDHeader: String

    /// Emit a W3C `traceparent` header (`00-<32hex>-<16hex>-01`). Off by default.
    public var emitW3CTraceparent: Bool

    public init(
        requestIDHeader: String = "X-Request-ID",
        correlationIDHeader: String = "X-Correlation-ID",
        emitW3CTraceparent: Bool = false
    ) {
        self.requestIDHeader = requestIDHeader
        self.correlationIDHeader = correlationIDHeader
        self.emitW3CTraceparent = emitW3CTraceparent
    }

    /// No tracing headers at all.
    public static let disabled = TraceHeaders(requestIDHeader: "", correlationIDHeader: "", emitW3CTraceparent: false)
}
