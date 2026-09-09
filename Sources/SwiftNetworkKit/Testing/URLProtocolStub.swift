import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A `URLProtocol` that intercepts every request so tests can exercise a *real* `URLSession`
/// (and thus ``URLSessionTransport``) without touching the network.
///
/// ```swift
/// let configuration = URLSessionConfiguration.ephemeral
/// configuration.protocolClasses = [URLProtocolStub.self]
/// let transport = URLSessionTransport(session: URLSession(configuration: configuration))
/// URLProtocolStub.respond(status: 200, body: Data("{}".utf8))
/// ```
///
/// Not thread-safe across concurrent tests — keep suites that use it `.serialized`.
@_spi(SwiftNetworkKitTesting) public final class URLProtocolStub: URLProtocol {

    @_spi(SwiftNetworkKitTesting) public struct Response: Sendable {
        @_spi(SwiftNetworkKitTesting) public var statusCode: Int
        @_spi(SwiftNetworkKitTesting) public var headers: [String: String]
        @_spi(SwiftNetworkKitTesting) public var body: Data
    }

    private struct State: @unchecked Sendable {
        var response: Response?
        var error: (any Error)?
        var lastRequest: URLRequest?
    }

    nonisolated(unsafe) private static var state = State()
    private static let lock = NSLock()

    /// Configures a successful stub response.
    @_spi(SwiftNetworkKitTesting) public static func respond(
        status: Int = 200, headers: [String: String] = [:], body: Data = Data()
    ) {
        lock.lock()
        defer { lock.unlock() }
        state = State(
            response: Response(statusCode: status, headers: headers, body: body), error: nil, lastRequest: nil)
    }

    /// Configures the stub to fail with `error`.
    @_spi(SwiftNetworkKitTesting) public static func fail(with error: any Error) {
        lock.lock()
        defer { lock.unlock() }
        state = State(response: nil, error: error, lastRequest: nil)
    }

    /// The most recent request that reached the stub.
    @_spi(SwiftNetworkKitTesting) public static var lastRequest: URLRequest? {
        lock.lock()
        defer { lock.unlock() }
        return state.lastRequest
    }

    /// Clears all configuration. Call in test teardown.
    @_spi(SwiftNetworkKitTesting) public static func reset() {
        lock.lock()
        defer { lock.unlock() }
        state = State()
    }

    // MARK: URLProtocol

    override public class func canInit(with request: URLRequest) -> Bool { true }
    override public class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override public func startLoading() {
        Self.lock.lock()
        Self.state.lastRequest = request
        let response = Self.state.response
        let error = Self.state.error
        Self.lock.unlock()

        if let error {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        guard let response, let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let httpResponse = HTTPURLResponse(
            url: url,
            statusCode: response.statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: response.headers
        )!
        client?.urlProtocol(self, didReceive: httpResponse, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: response.body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override public func stopLoading() {}
}
