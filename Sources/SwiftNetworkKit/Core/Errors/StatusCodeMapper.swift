import Foundation

/// The one place HTTP status codes become ``NetworkError`` values.
///
/// Apps customize the mapping by passing an `errorMapper` (see ``NetworkConfiguration``) — it is
/// consulted first and any non-`nil` result wins.
enum StatusCodeMapper {

    /// Maps a response to a `NetworkError`, or returns `nil` for 2xx and 304 (both are "success"
    /// from the transport's point of view — 304 is resolved by the cache layer in M8).
    static func map(
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

    /// The longest `Retry-After` value the parser will report. A hostile server can send
    /// `Retry-After: 1e30`; anything past a day is meaningless to a client and an unbounded value
    /// crashes `Int(_:)` conversions downstream (e.g. in `errorDescription`).
    static let maxRetryAfter: TimeInterval = 24 * 60 * 60

    /// Parses a `Retry-After` header: either delta-seconds or an HTTP-date. Clamped to
    /// `[0, maxRetryAfter]`; non-finite or unparseable values return `nil`.
    static func retryAfterInterval(from headers: HTTPHeaders) -> TimeInterval? {
        guard let raw = headers["Retry-After"]?.trimmingCharacters(in: .whitespaces), !raw.isEmpty else {
            return nil
        }
        if let seconds = TimeInterval(raw), seconds.isFinite {
            return min(max(0, seconds), maxRetryAfter)
        }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
        if let date = formatter.date(from: raw) {
            return min(max(0, date.timeIntervalSinceNow), maxRetryAfter)
        }
        return nil
    }
}
