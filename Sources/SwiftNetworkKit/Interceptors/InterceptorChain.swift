import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Runs the configured request and response interceptors around a single transport round-trip.
///
/// Request interceptors run in array order; response interceptors run in reverse (middleware
/// semantics). Interceptor-driven retries are capped by the caller at 2 per request.
struct InterceptorChain: Sendable {
    let requestInterceptors: [any RequestInterceptor]
    let responseInterceptors: [any ResponseInterceptor]

    var isEmpty: Bool { requestInterceptors.isEmpty && responseInterceptors.isEmpty }

    func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
        var request = request
        for interceptor in requestInterceptors {
            request = try await interceptor.adapt(request, for: endpoint)
        }
        return request
    }

    /// The pipeline's next move after the response interceptors have had their say.
    enum Resolution: Sendable {
        /// Continue to status mapping / decoding with this (possibly substituted) body.
        case proceed(Data)
        /// Re-send the request after this delay.
        case retry(after: TimeInterval)
        /// Fail now.
        case fail(NetworkError)
    }

    func resolve(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> Resolution {
        var body = context.data ?? Data()
        for interceptor in responseInterceptors.reversed() {
            switch try await interceptor.process(context, for: endpoint) {
            case .proceed:
                continue
            case .substitute(let data):
                body = data
            case .retry(let after):
                return .retry(after: after)
            case .fail(let error):
                return .fail(error)
            }
        }
        return .proceed(body)
    }
}
