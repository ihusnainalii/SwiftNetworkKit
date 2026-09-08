import Foundation

/// The one place HTTP status codes become ``NetworkError`` values.
///
/// Apps customize the mapping by passing an `errorMapper` (see ``NetworkConfiguration``) — it is
/// consulted first and any non-`nil` result wins.
public enum StatusCodeMapper {

    /// Maps a response to a `NetworkError`, or returns `nil` for 2xx and 304 (both are "success"
    /// from the transport's point of view — 304 is resolved by the cache layer in M8).
    public static func map(
        context: ResponseContext,
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) -> NetworkError? {
        let code = context.statusCode
        if HTTPStatus.isSuccess(code) || code == 304 { return nil }

        if let custom = errorMapper?(context) { return custom }

        switch code {
        case 400, 422:
            return .validation(context)
        case 401:
            return .unauthorized(context)
        case 403:
            return .forbidden(context)
        case 404:
            return .notFound(context)
        case 408:
            return .timeout
        case 429:
            return .rateLimited(retryAfter: retryAfterInterval(from: context.headers), context)
        case 500...599:
            return .server(context)
        default:
            return .unacceptableStatusCode(code, context)
        }
    }

    /// Parses a `Retry-After` header: either delta-seconds or an HTTP-date.
    static func retryAfterInterval(from headers: HTTPHeaders) -> TimeInterval? {
        guard let raw = headers["Retry-After"]?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
            return nil
        }
        if let seconds = TimeInterval(raw) {
            return max(0, seconds)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        if let date = formatter.date(from: raw) {
            return max(0, date.timeIntervalSinceNow)
        }
        return nil
    }
}
