import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("URLSessionTransport", .serialized)
struct URLSessionTransportTests {

    private func makeTransport() -> URLSessionTransport {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSessionTransport(session: URLSession(configuration: configuration))
    }

    init() { URLProtocolStub.reset() }

    @Test("returns body and HTTPURLResponse on success")
    func success() async throws {
        URLProtocolStub.respond(status: 201, headers: ["X-Trace": "abc"], body: Data("hi".utf8))
        let (data, response) = try await makeTransport().data(
            for: URLRequest(url: URL(string: "https://example.com/x")!)
        )
        #expect(data == Data("hi".utf8))
        #expect(response.statusCode == 201)
        #expect(response.value(forHTTPHeaderField: "X-Trace") == "abc")
    }

    @Test("maps a timeout URLError to NetworkError.timeout")
    func timeout() async {
        URLProtocolStub.fail(with: URLError(.timedOut))
        let error = await #expect(throws: NetworkError.self) {
            try await makeTransport().data(for: URLRequest(url: URL(string: "https://example.com/x")!))
        }
        #expect(error?.code == .timeout)
    }

    @Test("maps a connectivity URLError to NetworkError.noInternet")
    func offline() async {
        URLProtocolStub.fail(with: URLError(.notConnectedToInternet))
        let error = await #expect(throws: NetworkError.self) {
            try await makeTransport().data(for: URLRequest(url: URL(string: "https://example.com/x")!))
        }
        #expect(error?.code == .noInternet)
    }

    @Test("records the request that reached the transport")
    func recordsRequest() async throws {
        URLProtocolStub.respond(body: Data("{}".utf8))
        var request = URLRequest(url: URL(string: "https://example.com/track")!)
        request.httpMethod = "POST"
        _ = try await makeTransport().data(for: request)
        #expect(URLProtocolStub.lastRequest?.url?.path == "/track")
    }
}
