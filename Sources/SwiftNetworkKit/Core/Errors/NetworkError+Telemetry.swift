import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension ResponseContext {

    /// A copy that is safe to hand to a telemetry sink. The response body and the request body are
    /// dropped, credential headers and sensitive URL query values are masked, and the status code is
    /// kept. A custom ``NetworkMetrics`` that serializes events (Sentry, Datadog) then cannot exfiltrate
    /// a bearer token or a response payload.
    func sanitizedForTelemetry(using redactor: Redactor) -> ResponseContext {
        let url = request.url.flatMap { URL(string: redactor.redact(url: $0)) } ?? URL(fileURLWithPath: "/")
        var safeRequest = URLRequest(url: url)
        safeRequest.httpMethod = request.httpMethod
        let requestHeaders = HTTPHeaders(request.allHTTPHeaderFields ?? [:])
        for element in redactor.redact(headers: requestHeaders) {
            safeRequest.setValue(element.value, forHTTPHeaderField: element.name)
        }
        return ResponseContext(
            statusCode: statusCode,
            headers: redactor.redact(headers: headers),
            data: nil,
            request: safeRequest
        )
    }
}

extension NetworkError {

    /// This error with any ``ResponseContext`` replaced by its telemetry-safe form.
    func sanitizedForTelemetry(using redactor: Redactor) -> NetworkError {
        func clean(_ context: ResponseContext) -> ResponseContext {
            context.sanitizedForTelemetry(using: redactor)
        }
        switch self {
        case .unauthorized(let context): return .unauthorized(clean(context))
        case .forbidden(let context): return .forbidden(clean(context))
        case .notFound(let context): return .notFound(clean(context))
        case .validation(let context): return .validation(clean(context))
        case .server(let context): return .server(clean(context))
        case .rateLimited(let retryAfter, let context): return .rateLimited(retryAfter: retryAfter, clean(context))
        case .unacceptableStatusCode(let status, let context): return .unacceptableStatusCode(status, clean(context))
        case .decoding(let underlying, let context): return .decoding(underlying: underlying, context.map(clean))
        default: return self
        }
    }
}
