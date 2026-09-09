import Foundation

/// The single error type crossing SwiftNetworkKit's public boundary.
///
/// Internal errors (`URLError`, `DecodingError`, keychain `OSStatus`, trust-evaluation failures, …)
/// are all mapped into one of these cases before they reach a caller.
public enum NetworkError: Error, Sendable {
    case invalidURL(String)
    case noInternet
    case timeout
    case unauthorized(ResponseContext)
    case forbidden(ResponseContext)
    case notFound(ResponseContext)
    case validation(ResponseContext)
    case rateLimited(retryAfter: TimeInterval?, ResponseContext)
    case server(ResponseContext)
    case unacceptableStatusCode(Int, ResponseContext)
    case decoding(underlying: any Error & Sendable, ResponseContext?)
    case encoding(underlying: any Error & Sendable)
    case sslPinningFailed(host: String)
    case tokenRefreshFailed(underlying: any Error & Sendable)
    case sessionExpired
    case cancelled
    case offline
    /// The request was persisted to the offline queue; its replay outcome arrives on
    /// ``NetworkClient/offlineReplayEvents()``.
    case offlineQueued(RequestID)
    case transport(underlying: any Error & Sendable)
    case unknown(underlying: (any Error & Sendable)?)
}

extension NetworkError {
    /// A stable, `Equatable` discriminant, handy for `switch`ing and for tests.
    public enum Code: String, Sendable, Hashable, CaseIterable {
        case invalidURL, noInternet, timeout, unauthorized, forbidden, notFound
        case validation, rateLimited, server, unacceptableStatusCode, decoding, encoding
        case sslPinningFailed, tokenRefreshFailed, sessionExpired, cancelled, offline, offlineQueued
        case transport, unknown
    }

    public var code: Code {
        switch self {
        case .invalidURL: .invalidURL
        case .noInternet: .noInternet
        case .timeout: .timeout
        case .unauthorized: .unauthorized
        case .forbidden: .forbidden
        case .notFound: .notFound
        case .validation: .validation
        case .rateLimited: .rateLimited
        case .server: .server
        case .unacceptableStatusCode: .unacceptableStatusCode
        case .decoding: .decoding
        case .encoding: .encoding
        case .sslPinningFailed: .sslPinningFailed
        case .tokenRefreshFailed: .tokenRefreshFailed
        case .sessionExpired: .sessionExpired
        case .cancelled: .cancelled
        case .offline: .offline
        case .offlineQueued: .offlineQueued
        case .transport: .transport
        case .unknown: .unknown
        }
    }

    /// The response context, for the cases that carry one.
    public var responseContext: ResponseContext? {
        switch self {
        case .unauthorized(let context), .forbidden(let context), .notFound(let context),
            .validation(let context), .server(let context):
            context
        case .rateLimited(_, let context), .unacceptableStatusCode(_, let context):
            context
        case .decoding(_, let context):
            context
        default:
            nil
        }
    }

    /// HTTP status code, when the error originated from a response.
    public var statusCode: Int? { responseContext?.statusCode }

    /// Response headers, when available.
    public var responseHeaders: HTTPHeaders? { responseContext?.headers }

    /// Raw response body, when available.
    public var responseData: Data? { responseContext?.data }

    /// Server-supplied message, when the body carried one.
    public var serverMessage: String? { responseContext?.serverMessage }

    /// Whether re-attempting the same request could plausibly succeed.
    ///
    /// An advisory hint for callers, e.g. whether to show a "Try again" affordance.
    /// The client's own automatic retries are driven separately by ``RetryPolicy``;
    /// this does not consult it.
    public var isRetryable: Bool {
        switch self {
        case .noInternet, .timeout, .offline, .rateLimited, .server, .transport:
            true
        case .unacceptableStatusCode(let status, _):
            status == 408 || (500...599).contains(status)
        case .invalidURL, .unauthorized, .forbidden, .notFound, .validation, .decoding,
            .encoding, .sslPinningFailed, .tokenRefreshFailed, .sessionExpired, .cancelled,
            .offlineQueued, .unknown:
            false
        }
    }

    /// Normalizes an arbitrary thrown error: passes ``NetworkError`` through untouched,
    /// maps `URLError` / cancellation, and wraps anything else as `.unknown`.
    public static func normalize(_ error: any Error) -> NetworkError {
        switch error {
        case let networkError as NetworkError:
            return networkError
        case is CancellationError:
            return .cancelled
        case let urlError as URLError:
            switch urlError.code {
            case .cancelled: return .cancelled
            case .timedOut: return .timeout
            case .notConnectedToInternet, .networkConnectionLost, .dataNotAllowed:
                return .noInternet
            default:
                return .transport(underlying: urlError)
            }
        default:
            return .unknown(underlying: asSendableError(error))
        }
    }
}

extension NetworkError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL(let value): "Invalid URL: \(value)"
        case .noInternet: "No internet connection"
        case .timeout: "The request timed out"
        case .unauthorized: "Unauthorized (401)"
        case .forbidden: "Forbidden (403)"
        case .notFound: "Not found (404)"
        case .validation(let context): context.serverMessage ?? "Validation failed (\(context.statusCode))"
        case .rateLimited(let retryAfter, _):
            retryAfter.map { seconds in
                // Guard against a non-finite / huge value passed to a direct `.rateLimited(...)`
                // construction: `Int(_:)` traps on anything past `Int.max`.
                let safe = seconds.isFinite ? Int(min(max(0, seconds), 86_400)) : 0
                return "Rate limited, retry after \(safe)s"
            } ?? "Rate limited (429)"
        case .server(let context): context.serverMessage ?? "Server error (\(context.statusCode))"
        case .unacceptableStatusCode(let code, let context):
            context.serverMessage ?? "Unexpected status code \(code)"
        case .decoding(let underlying, _): "Failed to decode response: \(underlying)"
        case .encoding(let underlying): "Failed to encode request: \(underlying)"
        case .sslPinningFailed(let host): "SSL pinning validation failed for \(host)"
        case .tokenRefreshFailed(let underlying): "Token refresh failed: \(underlying)"
        case .sessionExpired: "The session has expired"
        case .cancelled: "The request was cancelled"
        case .offline: "The device is offline"
        case .offlineQueued(let id): "Offline: request \(id) queued for replay"
        case .transport(let underlying): "Transport error: \(underlying)"
        case .unknown(let underlying): underlying.map { "Unknown error: \($0)" } ?? "An unknown error occurred"
        }
    }
}
