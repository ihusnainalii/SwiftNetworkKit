import Foundation

/// The logging sink: receives fully-formatted, already-redacted lines. `NetworkClient` does the
/// formatting and redaction (via ``Redactor``) and skips every call when the active ``LogLevel`` is
/// ``LogLevel/none``.
///
/// Default: ``ConsoleNetworkLogger``. Tests: `CapturingLogger`.
public protocol NetworkLogger: Sendable {
    /// - Parameters:
    ///   - line: a single ready-to-emit log line (no secrets — redaction already applied).
    ///   - level: the level this line was produced at (`.error` for failures, else `.basic`+).
    func log(_ line: String, level: LogLevel)
}
