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
}
