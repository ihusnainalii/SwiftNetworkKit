import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("RequestBuilder")
struct RequestBuilderTests {

    private func config(
        baseURL: String = "https://api.example.com",
        headers: HTTPHeaders = [:]
    ) -> NetworkConfiguration {
        NetworkConfiguration(baseURL: baseURL, headers: headers)
    }

    private struct StubEndpoint: Endpoint {
        typealias Response = Data
        var path: String
        var method: HTTPMethod = .get
        var headers: HTTPHeaders = [:]
        var queryParameters: QueryParameters?
        var pathParameters: [String: String] = [:]
        var body: RequestBody?
        var timeout: TimeInterval?
    }

    private func build(_ endpoint: StubEndpoint, _ configuration: NetworkConfiguration) throws -> URLRequest {
        try RequestBuilder.build(
            endpoint: endpoint,
            environment: configuration.environment,
            configuration: configuration
        )
    }

    @Test("path parameters are substituted")
    func pathParameters() throws {
        let request = try build(
            StubEndpoint(path: "/users/:id/posts/:postID", pathParameters: ["id": "42", "postID": "7"]),
            config()
        )
        #expect(request.url?.path == "/users/42/posts/7")
    }

    @Test("a path parameter cannot escape its segment")
    func pathParameterSegmentInjection() throws {
        // Values that would otherwise inject a path separator or a bare-dot segment.
        for value in ["../admin", "1/delete", "..", ".", "a/b/c", "x/../y"] {
            let request = try build(StubEndpoint(path: "/users/:id", pathParameters: ["id": value]), config())
            let absolute = try #require(request.url?.absoluteString)
            // The base path is intact and the value stayed one (opaque) segment.
            #expect(absolute.hasPrefix("https://api.example.com/users/"), "\(value) -> \(absolute)")
            let segment = String(absolute.dropFirst("https://api.example.com/users/".count))
            #expect(!segment.contains("/"), "\(value) leaked a '/' -> \(absolute)")
            #expect(segment != "." && segment != "..", "\(value) stayed a dot segment -> \(absolute)")
        }
        // Normalization does not collapse it to the parent.
        let request = try build(StubEndpoint(path: "/users/:id", pathParameters: ["id": "../admin"]), config())
        #expect(request.url?.standardized.absoluteString.contains("/admin") != true)
    }

    @Test("slash between base and path is normalized to exactly one")
    func slashNormalization() throws {
        let cases: [(base: String, path: String)] = [
            ("https://api.example.com", "/v1/me"),
            ("https://api.example.com/", "/v1/me"),
            ("https://api.example.com/", "v1/me"),
            ("https://api.example.com", "v1/me"),
        ]
        for c in cases {
            let request = try build(StubEndpoint(path: c.path), config(baseURL: c.base))
            #expect(request.url?.absoluteString == "https://api.example.com/v1/me", "\(c)")
        }
    }

    @Test("query parameters are attached and percent-encoded")
    func query() throws {
        var query = QueryParameters()
        query.append("q", .string("a+b"))
        query.append("tag", .list(["x", "y"]))
        let request = try build(StubEndpoint(path: "/search", queryParameters: query), config())
        let url = try #require(request.url?.absoluteString)
        #expect(url.contains("q=a%2Bb"))
        #expect(url.contains("tag=x&tag=y"))
    }

    @Test("endpoint headers win over environment headers")
    func headerPrecedence() throws {
        let configuration = config(headers: ["X-App": "1", "Accept": "application/json"])
        let request = try build(
            StubEndpoint(path: "/x", headers: ["Accept": "text/plain", "X-Extra": "y"]),
            configuration
        )
        #expect(request.value(forHTTPHeaderField: "X-App") == "1")
        #expect(request.value(forHTTPHeaderField: "Accept") == "text/plain")
        #expect(request.value(forHTTPHeaderField: "X-Extra") == "y")
    }

    @Test("body encodes and sets Content-Type per kind")
    func bodyContentType() throws {
        let json = try build(StubEndpoint(path: "/x", method: .post, body: .data(Data("{}".utf8))), config())
        #expect(json.httpBody == Data("{}".utf8))

        let jsonValue = try build(
            StubEndpoint(path: "/x", method: .post, body: .formURLEncoded(["a": "1"])),
            config()
        )
        #expect(
            jsonValue.value(forHTTPHeaderField: "Content-Type")?.hasPrefix("application/x-www-form-urlencoded") == true)
    }

    @Test("explicit Content-Type header is not overridden by the body")
    func explicitContentType() throws {
        let request = try build(
            StubEndpoint(
                path: "/x", method: .post, headers: ["Content-Type": "application/vnd.api+json"],
                body: .formURLEncoded(["a": "1"])),
            config()
        )
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/vnd.api+json")
    }

    @Test("timeout: endpoint overrides environment")
    func timeout() throws {
        var configuration = config()
        configuration.environment.timeout = 30
        #expect(try build(StubEndpoint(path: "/x"), configuration).timeoutInterval == 30)
        #expect(try build(StubEndpoint(path: "/x", timeout: 5), configuration).timeoutInterval == 5)
    }

    @Test("weird-but-parseable paths still produce a percent-encoded URL")
    func lenientPathEncoding() throws {
        // Foundation's `URL(string:)` is lenient and encodes spaces/control chars rather than
        // returning nil, so `.invalidURL` is a rare defensive path. Here we just confirm the
        // builder yields a usable URL.
        let request = try build(StubEndpoint(path: "/a b/c"), config())
        #expect(request.url?.absoluteString == "https://api.example.com/a%20b/c")
    }
}
