import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

@Suite("NetworkError")
struct NetworkErrorTests {

    private func context(_ code: Int) -> ResponseContext {
        ResponseContext(
            statusCode: code,
            headers: ["X-Trace": "abc"],
            data: Data(#"{"message":"nope"}"#.utf8),
            request: URLRequest(url: URL(string: "https://example.com")!)
        )
    }

    @Test("serverMessage reads the common error-body shapes")
    func serverMessageShapes() {
        func message(_ body: String) -> String? {
            ResponseContext(
                statusCode: 422, headers: [:], data: Data(body.utf8),
                request: URLRequest(url: URL(string: "https://x")!)
            ).serverMessage
        }
        #expect(message(#"{"message":"bad input"}"#) == "bad input")
        #expect(message(#"{"error":"nope"}"#) == "nope")
        #expect(message(#"{"errors":[{"message":"field required"}]}"#) == "field required")
        #expect(message(#"{"errors":["first","second"]}"#) == "first")
        #expect(message("plain text failure") == "plain text failure")
        #expect(message(String(repeating: "x", count: 900)) == nil)  // too long to be a message
        #expect(message("") == nil)
    }

    @Test("response-carrying cases expose status, headers, body, message")
    func responseAccessors() {
        let error = NetworkError.server(context(503))
        #expect(error.statusCode == 503)
        #expect(error.responseHeaders?["x-trace"] == "abc")
        #expect(error.serverMessage == "nope")
        #expect(error.responseData != nil)
    }

    @Test("non-response cases expose nil context")
    func noContext() {
        #expect(NetworkError.cancelled.responseContext == nil)
        #expect(NetworkError.noInternet.statusCode == nil)
    }

    @Test("normalize passes NetworkError through untouched")
    func normalizePassthrough() {
        let original = NetworkError.sessionExpired
        #expect(NetworkError.normalize(original).code == .sessionExpired)
    }

    @Test("normalize maps URLError codes")
    func normalizeURLError() {
        #expect(NetworkError.normalize(URLError(.timedOut)).code == .timeout)
        #expect(NetworkError.normalize(URLError(.cancelled)).code == .cancelled)
        #expect(NetworkError.normalize(URLError(.notConnectedToInternet)).code == .noInternet)
        #expect(NetworkError.normalize(URLError(.badServerResponse)).code == .transport)
    }

    @Test("normalize maps CancellationError")
    func normalizeCancellation() {
        #expect(NetworkError.normalize(CancellationError()).code == .cancelled)
    }

    @Test("normalize wraps an arbitrary error as .unknown carrying a SendableErrorBox")
    func normalizeUnknown() {
        struct Weird: Error {}
        let normalized = NetworkError.normalize(Weird())
        #expect(normalized.code == .unknown)
        guard case .unknown(let underlying) = normalized else {
            Issue.record("expected .unknown")
            return
        }
        let box = try? #require(underlying as? SendableErrorBox)
        #expect(box?.underlyingType.contains("Weird") == true)
    }

    @Test("asSendableError passes URLError, DecodingError and EncodingError through untouched")
    func asSendableErrorPassesThroughKnownTypes() {
        let urlError = URLError(.timedOut)
        #expect(asSendableError(urlError) as? URLError == urlError)

        let decodingError = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "x"))
        #expect(asSendableError(decodingError) is DecodingError)

        let encodingError = EncodingError.invalidValue(1, .init(codingPath: [], debugDescription: "x"))
        #expect(asSendableError(encodingError) is EncodingError)

        // Anything else is still boxed, so NetworkError stays fully Sendable.
        struct Weird: Error {}
        #expect(asSendableError(Weird()) is SendableErrorBox)
    }

    @Test("a decode failure carries the real DecodingError, not a box")
    func decodingFailureCarriesRealDecodingError() async throws {
        struct Thing: Codable, Sendable {}
        struct GetThing: Endpoint {
            typealias Response = Thing
            let path = "/thing"
        }
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        let transport = MockNetworkTransport(default: .json(Data("not json".utf8)))
        let client = NetworkClient(configuration: config, transport: transport)

        let error = await #expect(throws: NetworkError.self) { try await client.request(GetThing()) }
        guard case .decoding(let underlying, _) = error else {
            Issue.record("expected .decoding")
            return
        }
        #expect(underlying is DecodingError)
    }

    @Test("isRetryable flags transient failures only")
    func isRetryable() {
        let retryable: [NetworkError] = [
            .noInternet, .timeout, .offline, .server(context(500)),
            .rateLimited(retryAfter: 1, context(429)), .transport(underlying: URLError(.networkConnectionLost)),
            .unacceptableStatusCode(503, context(503)), .unacceptableStatusCode(408, context(408)),
        ]
        let notRetryable: [NetworkError] = [
            .invalidURL("x"), .unauthorized(context(401)), .forbidden(context(403)),
            .notFound(context(404)), .validation(context(422)), .sslPinningFailed(host: "api.example.com"),
            .sessionExpired, .cancelled, .encoding(underlying: URLError(.badURL)),
            .unacceptableStatusCode(400, context(400)), .unknown(underlying: nil),
        ]
        for error in retryable { #expect(error.isRetryable, "\(error.code) should be retryable") }
        for error in notRetryable { #expect(!error.isRetryable, "\(error.code) should not be retryable") }
    }

    @Test("every case has a localized description")
    func localizedDescriptions() {
        let samples: [NetworkError] = [
            .invalidURL("x"), .noInternet, .timeout, .sessionExpired, .cancelled, .offline,
            .sslPinningFailed(host: "api.example.com"), .server(context(500)),
        ]
        for error in samples {
            #expect(!(error.errorDescription ?? "").isEmpty)
        }
    }
}
