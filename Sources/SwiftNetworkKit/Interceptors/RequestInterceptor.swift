import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Adapts an outgoing `URLRequest` just before it is sent. Runs after auth and tracing, in the order
/// interceptors appear in ``NetworkConfiguration/requestInterceptors``.
///
/// Use for cross-cutting request concerns: extra headers, signing, feature flags, locale.
public protocol RequestInterceptor: Sendable {
    func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest
}
