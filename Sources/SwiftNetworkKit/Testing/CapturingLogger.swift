import Foundation

/// A ``NetworkLogger`` that keeps every line in memory for assertions.
public final class CapturingLogger: NetworkLogger, @unchecked Sendable {

    private let lock = NSLock()
    private var _lines: [(line: String, level: LogLevel)] = []

    public init() {}

    public func log(_ line: String, level: LogLevel) {
        lock.withLock { _lines.append((line, level)) }
    }

    /// Every captured line, in order.
    public var lines: [String] {
        lock.withLock { _lines.map(\.line) }
    }

    /// Captured lines paired with the level they were emitted at.
    public var entries: [(line: String, level: LogLevel)] {
        lock.withLock { _lines }
    }

    public func clear() {
        lock.withLock { _lines.removeAll() }
    }
}
