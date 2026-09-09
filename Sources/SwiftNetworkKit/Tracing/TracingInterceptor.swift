import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Attaches correlation headers to every outgoing request per ``TraceHeaders``.
///
/// `NetworkClient` inserts this ahead of the app's own request interceptors, so they can read or
/// override what it set.
public struct TracingInterceptor: RequestInterceptor {
    public let headers: TraceHeaders

    public init(_ headers: TraceHeaders = TraceHeaders()) {
        self.headers = headers
    }

    public func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
        var request = request

        if !headers.requestIDHeader.isEmpty {
            request.setValue(UUID().uuidString, forHTTPHeaderField: headers.requestIDHeader)
        }
        if !headers.correlationIDHeader.isEmpty, let correlationID = TraceContext.correlationID {
            request.setValue(correlationID, forHTTPHeaderField: headers.correlationIDHeader)
        }
        if headers.emitW3CTraceparent {
            request.setValue(Self.traceparent(), forHTTPHeaderField: "traceparent")
        }
        return request
    }

    /// `00-<16 random bytes>-<8 random bytes>-01`
    static func traceparent() -> String {
        func hex(_ byteCount: Int) -> String {
            (0..<byteCount).map { _ in String(format: "%02x", UInt8.random(in: .min ... .max)) }.joined()
        }
        return "00-\(hex(16))-\(hex(8))-01"
    }
}
