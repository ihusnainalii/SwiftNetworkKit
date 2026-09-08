import Foundation

/// A named set of connection settings. An app can hold several and switch between them.
///
/// Milestone-added fields (SSL pins in M5, retry policy in M3, per-environment cache config in M8)
/// attach here as those types are introduced.
public struct NetworkEnvironment: Sendable {
    public var kind: EnvironmentKind
    public var baseURL: URL
    public var defaultHeaders: HTTPHeaders
    public var timeout: TimeInterval
    public var logLevel: LogLevel

    public init(
        kind: EnvironmentKind,
        baseURL: URL,
        defaultHeaders: HTTPHeaders = [:],
        timeout: TimeInterval = 60,
        logLevel: LogLevel = .basic
    ) {
        self.kind = kind
        self.baseURL = baseURL
        self.defaultHeaders = defaultHeaders
        self.timeout = timeout
        self.logLevel = logLevel
    }
}

public extension NetworkEnvironment {
    static func development(baseURL: URL, headers: HTTPHeaders = [:], timeout: TimeInterval = 60) -> NetworkEnvironment {
        NetworkEnvironment(kind: .development, baseURL: baseURL, defaultHeaders: headers, timeout: timeout, logLevel: .debug)
    }

    static func qa(baseURL: URL, headers: HTTPHeaders = [:], timeout: TimeInterval = 60) -> NetworkEnvironment {
        NetworkEnvironment(kind: .qa, baseURL: baseURL, defaultHeaders: headers, timeout: timeout, logLevel: .verbose)
    }

    static func staging(baseURL: URL, headers: HTTPHeaders = [:], timeout: TimeInterval = 60) -> NetworkEnvironment {
        NetworkEnvironment(kind: .staging, baseURL: baseURL, defaultHeaders: headers, timeout: timeout, logLevel: .basic)
    }

    static func production(baseURL: URL, headers: HTTPHeaders = [:], timeout: TimeInterval = 60) -> NetworkEnvironment {
        NetworkEnvironment(kind: .production, baseURL: baseURL, defaultHeaders: headers, timeout: timeout, logLevel: .error)
    }
}
