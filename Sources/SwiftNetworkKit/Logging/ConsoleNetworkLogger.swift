import Foundation
#if canImport(os)
import os
#endif

/// The default ``NetworkLogger``. Routes lines to the unified logging system (`os.Logger`) on Apple
/// platforms, and to `print` elsewhere.
///
/// The whole line is already redacted by the time it arrives, so it is logged `.public` — a token
/// never reaches here.
public struct ConsoleNetworkLogger: NetworkLogger {

    #if canImport(os)
    private let logger: os.Logger

    public init(subsystem: String = "SwiftNetworkKit", category: String = "network") {
        self.logger = os.Logger(subsystem: subsystem, category: category)
    }
    #else
    public init(subsystem: String = "SwiftNetworkKit", category: String = "network") {}
    #endif

    public func log(_ line: String, level: LogLevel) {
        #if canImport(os)
        switch level {
        case .error:
            logger.error("\(line, privacy: .public)")
        default:
            logger.log("\(line, privacy: .public)")
        }
        #else
        print(line)
        #endif
    }
}
