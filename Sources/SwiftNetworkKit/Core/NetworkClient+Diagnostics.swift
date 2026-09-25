import Foundation

extension NetworkClient {

    var logLevel: LogLevel { configuration.environment.logLevel }

    func elapsed(since start: ContinuousClock.Instant) -> Duration {
        start.duration(to: configuration.clock.now())
    }

    func emit(_ lines: [String], level: LogLevel) {
        guard logLevel != .none, !lines.isEmpty else { return }
        for line in lines { configuration.logger.log(line, level: level) }
    }

    func recordFailure(
        _ error: NetworkError, requestID: RequestID, status: Int?, since start: ContinuousClock.Instant
    ) async {
        // Metrics sinks are often shipped off-device, so they get the error without bodies or credentials.
        let safe = error.sanitizedForTelemetry(using: logFormatter.redactor)
        await configuration.metrics.record(.failure(requestID, safe, status: status ?? error.statusCode))
        if error.code == .timeout { await configuration.metrics.record(.timeout(requestID)) }
        if let line = logFormatter.failureLine(error, duration: elapsed(since: start), level: logLevel) {
            configuration.logger.log(line, level: .error)
        }
    }
}
