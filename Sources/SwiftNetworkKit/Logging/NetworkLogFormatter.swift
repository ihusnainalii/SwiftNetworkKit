import Foundation

/// Turns pipeline events into log lines, applying ``Redactor`` and the active ``LogLevel``.
///
/// `basic` -> one line per request and per response. `verbose` adds redacted headers. `debug` adds
/// redacted bodies. `error` (and above) still emit the failure line; `none` produces nothing.
struct NetworkLogFormatter: Sendable {
    let redactor: Redactor

    func requestLines(_ request: URLRequest, endpoint: AnyEndpoint, level: LogLevel) -> [String] {
        guard level >= .basic else { return [] }
        let method = request.httpMethod ?? endpoint.method.rawValue
        let target = request.url?.absoluteString ?? endpoint.path
        var lines = ["\u{2192} \(method) \(target)"]
        if level >= .verbose {
            lines += headerLines(HTTPHeaders(request.allHTTPHeaderFields ?? [:]), arrow: "\u{2192}")
        }
        if level >= .debug, let body = request.httpBody {
            lines.append("\u{2192} body: \(redactor.redact(body: body))")
        }
        return lines
    }

    func responseLines(_ context: ResponseContext, duration: Duration, level: LogLevel) -> [String] {
        guard level >= .basic else { return [] }
        var lines = ["\u{2190} \(context.statusCode) (\(milliseconds(duration))ms)"]
        if level >= .verbose {
            lines += headerLines(context.headers, arrow: "\u{2190}")
        }
        if level >= .debug, let body = context.data, !body.isEmpty {
            lines.append("\u{2190} body: \(redactor.redact(body: body))")
        }
        return lines
    }

    func failureLine(_ error: NetworkError, duration: Duration, level: LogLevel) -> String? {
        guard level >= .error else { return nil }
        let status = error.statusCode.map { " \($0)" } ?? ""
        return "\u{2190} error\(status): \(error.code.rawValue) (\(milliseconds(duration))ms)"
    }

    private func headerLines(_ headers: HTTPHeaders, arrow: String) -> [String] {
        redactor.redact(headers: headers)
            .sorted { $0.name.lowercased() < $1.name.lowercased() }
            .map { "\(arrow) \($0.name): \($0.value)" }
    }

    private func milliseconds(_ duration: Duration) -> Int {
        let (seconds, attoseconds) = duration.components
        return Int((Double(seconds) + Double(attoseconds) / 1e18) * 1000)
    }
}
