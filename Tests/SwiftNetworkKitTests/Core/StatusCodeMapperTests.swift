import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("StatusCodeMapper")
struct StatusCodeMapperTests {

    private func context(_ code: Int, headers: HTTPHeaders = [:], body: Data? = nil) -> ResponseContext {
        ResponseContext(
            statusCode: code,
            headers: headers,
            data: body,
            request: URLRequest(url: URL(string: "https://example.com/resource")!)
        )
    }

    @Test("2xx and 304 map to nil")
    func successCodes() {
        #expect(StatusCodeMapper.map(context: context(200)) == nil)
        #expect(StatusCodeMapper.map(context: context(299)) == nil)
        #expect(StatusCodeMapper.map(context: context(304)) == nil)
    }

    @Test(
        "status code → error code",
        arguments: [
            (400, NetworkError.Code.validation),
            (401, .unauthorized),
            (403, .forbidden),
            (404, .notFound),
            (408, .timeout),
            (409, .unacceptableStatusCode),
            (418, .unacceptableStatusCode),
            (422, .validation),
            (429, .rateLimited),
            (500, .server),
            (502, .server),
            (503, .server),
            (504, .server),
        ])
    func mapping(status: Int, expected: NetworkError.Code) {
        #expect(StatusCodeMapper.map(context: context(status))?.code == expected)
    }

    @Test("Retry-After seconds are parsed on 429")
    func retryAfterSeconds() throws {
        let mapped = StatusCodeMapper.map(context: context(429, headers: ["Retry-After": "2"]))
        guard case .rateLimited(let retryAfter, _) = try #require(mapped) else {
            Issue.record("expected .rateLimited")
            return
        }
        #expect(retryAfter == 2)
    }

    @Test(
        "a hostile Retry-After is clamped and its description never traps",
        arguments: ["1e30", "99999999999999999999", "1E40", "-5", "inf", "nan", "not-a-number"])
    func retryAfterIsClamped(raw: String) throws {
        let mapped = StatusCodeMapper.map(context: context(429, headers: ["Retry-After": raw]))
        guard case .rateLimited(let retryAfter, _) = try #require(mapped) else {
            Issue.record("expected .rateLimited")
            return
        }
        if let retryAfter {
            #expect(retryAfter >= 0)
            #expect(retryAfter <= StatusCodeMapper.maxRetryAfter)
        }
        // errorDescription force-converted an unbounded Double to Int -> Fatal error. Must not now.
        _ = mapped?.localizedDescription
        _ = NetworkError.rateLimited(retryAfter: .infinity, context(429)).localizedDescription
    }

    @Test("custom error mapper wins")
    func customMapper() {
        let mapper: @Sendable (ResponseContext) -> NetworkError? = { _ in .sessionExpired }
        let mapped = StatusCodeMapper.map(context: context(500), errorMapper: mapper)
        #expect(mapped?.code == .sessionExpired)
    }

    @Test("server message is extracted from a JSON body")
    func serverMessage() {
        let body = Data(#"{"message":"boom"}"#.utf8)
        #expect(context(500, body: body).serverMessage == "boom")

        let nested = Data(#"{"errors":[{"message":"bad field"}]}"#.utf8)
        #expect(context(422, body: nested).serverMessage == "bad field")
    }
}
