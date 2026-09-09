import Foundation

/// A ``NetworkLogger`` that keeps every line in memory for assertions.
@_spi(SwiftNetworkKitTesting) public final class CapturingLogger: NetworkLogger, @unchecked Sendable {

    private let lock = NSLock()
    private var _lines: [(line: String, level: LogLevel)] = []

    @_spi(SwiftNetworkKitTesting) public init() {}

    @_spi(SwiftNetworkKitTesting) public func log(_ line: String, level: LogLevel) {
        lock.withLock { _lines.append((line, level)) }
    }

    /// Every captured line, in order.
    @_spi(SwiftNetworkKitTesting) public var lines: [String] {
        lock.withLock { _lines.map(\.line) }
    }

    /// Captured lines paired with the level they were emitted at.
    @_spi(SwiftNetworkKitTesting) public var entries: [(line: String, level: LogLevel)] {
        lock.withLock { _lines }
    }

    @_spi(SwiftNetworkKitTesting) public func clear() {
        lock.withLock { _lines.removeAll() }
    }
}
