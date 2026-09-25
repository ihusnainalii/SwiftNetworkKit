import Foundation

/// Parses the RFC 9110 `IMF-fixdate` used by `Retry-After` (`Sun, 06 Nov 1994 08:49:37 GMT`).
///
/// One shared formatter behind a lock, because building a `DateFormatter` is expensive and the type is
/// not `Sendable`.
final class HTTPDateParser: @unchecked Sendable {

    static let shared = HTTPDateParser()

    private let lock = NSLock()
    private let formatter: DateFormatter

    private init() {
        formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "GMT")
        formatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss 'GMT'"
    }

    func date(from string: String) -> Date? {
        lock.withLock { formatter.date(from: string) }
    }
}
