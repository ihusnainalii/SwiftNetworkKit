import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension NetworkClient {

    /// The transport used when the caller does not inject one: `URLSession`, with certificate or
    /// public-key pinning installed when the configuration asks for it.
    static func defaultTransport(for configuration: NetworkConfiguration) -> any NetworkTransport {
        let timeout = configuration.environment.timeout
        #if os(WASI)
        preconditionFailure("No default transport on WebAssembly; pass `transport:` explicitly.")
        #elseif canImport(Security)
        let host = URLComponents(url: configuration.environment.baseURL, resolvingAgainstBaseURL: false)?.host
        let resolved: SSLPinningConfiguration?
        do {
            resolved = try configuration.sslPinning.resolve(defaultHost: host)
        } catch {
            preconditionFailure("SSLPinning could not be resolved: \(error)")
        }
        guard let resolved else {
            return URLSessionTransport(timeout: timeout)
        }
        let logger = configuration.logger
        let evaluator = ServerTrustEvaluator(configuration: resolved) { line in
            logger.log(line, level: .error)
        }
        return URLSessionTransport(timeout: timeout, trustEvaluator: evaluator)
        #else
        return URLSessionTransport(timeout: timeout)
        #endif
    }

    // ponytail: this mirrors defaultTransport(for:) line for line instead of sharing a throwing core
    // that the trapping path force-unwraps. Keeping the two independent means a change to one can never
    // silently alter the other's crash behavior, which existing callers of the plain init depend on.
    /// Same resolution as ``defaultTransport(for:)``, but throws ``NetworkClientInitializationError``
    /// instead of trapping. Used by ``NetworkClient/validated(configuration:transport:refresh:onSessionExpired:)``.
    static func throwingDefaultTransport(for configuration: NetworkConfiguration) throws -> any NetworkTransport {
        let timeout = configuration.environment.timeout
        #if os(WASI)
        throw NetworkClientInitializationError.transportRequired
        #elseif canImport(Security)
        let host = URLComponents(url: configuration.environment.baseURL, resolvingAgainstBaseURL: false)?.host
        let resolved: SSLPinningConfiguration?
        do {
            resolved = try configuration.sslPinning.resolve(defaultHost: host)
        } catch let error as SSLPinningError {
            throw NetworkClientInitializationError.invalidPinningConfiguration(error)
        }
        guard let resolved else {
            return URLSessionTransport(timeout: timeout)
        }
        let logger = configuration.logger
        let evaluator = ServerTrustEvaluator(configuration: resolved) { line in
            logger.log(line, level: .error)
        }
        return URLSessionTransport(timeout: timeout, trustEvaluator: evaluator)
        #else
        return URLSessionTransport(timeout: timeout)
        #endif
    }

    /// Like ``init(configuration:transport:refresh:onSessionExpired:)``, but validates the default
    /// transport instead of trapping when it can't be built: a bundled pinning resource missing from a
    /// downstream build, a malformed pin hash, or (on WebAssembly) no `transport:` supplied where there
    /// is no default one.
    ///
    /// The plain initializer stays as it is (and still traps on these), because switching every caller
    /// to a throwing initializer would force `try` onto the overwhelming majority of call sites, for
    /// failure modes that are normally caught by CI long before they'd reach production. Use this
    /// initializer instead when the pinning configuration is not a fixed literal, for example when it
    /// is assembled from a remote config or a build flag, so a bad value is a request to handle rather
    /// than a crash.
    ///
    /// ```swift
    /// let client = try NetworkClient.validated(configuration: config)
    /// ```
    public static func validated(
        configuration: NetworkConfiguration,
        transport: (any NetworkTransport)? = nil,
        refresh: TokenManager.RefreshHandler? = nil,
        onSessionExpired: @escaping TokenManager.SessionExpiredHandler = {}
    ) throws -> NetworkClient {
        let resolvedTransport = try transport ?? Self.throwingDefaultTransport(for: configuration)
        return NetworkClient(
            configuration: configuration, transport: resolvedTransport, refresh: refresh,
            onSessionExpired: onSessionExpired)
    }
}
