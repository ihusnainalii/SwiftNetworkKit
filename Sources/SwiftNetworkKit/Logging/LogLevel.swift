/// Verbosity of network logging. Ordered from quietest to loudest.
///
/// The logging *sink* (`NetworkLogger`) and redaction arrive in milestone M4; this enum lands early
/// because ``NetworkEnvironment`` carries a default level per environment.
public enum LogLevel: Int, Sendable, Comparable, CaseIterable {
    /// Log nothing.
    case none = 0
    /// Log failed requests only.
    case error
    /// One line per request/response: method, URL, status, duration.
    case basic
    /// `basic` plus headers (redacted).
    case verbose
    /// `verbose` plus bodies (redacted).
    case debug

    public static func < (lhs: LogLevel, rhs: LogLevel) -> Bool { lhs.rawValue < rhs.rawValue }
}
