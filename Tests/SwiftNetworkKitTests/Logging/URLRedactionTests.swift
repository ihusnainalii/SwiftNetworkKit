import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

/// Credentials often travel in the query string, so a logged URL must never carry them.
@Suite("URL redaction")
struct URLRedactionTests {

    private struct Thing: Codable, Equatable, Sendable { let v: String }
    private struct SecureEndpoint: Endpoint {
        typealias Response = Thing
        let path = "/things"
        var authentication: AuthRequirement = .required
    }

    private func url(_ string: String) -> URL { URL(string: string)! }

    @Test("sensitive query values are masked and the rest of the URL is untouched")
    func masksSensitiveItems() {
        let redacted = Redactor().redact(url: url("https://api.example.com/v1/things?page=2&access_token=abc123&q=cat"))
        #expect(redacted == "https://api.example.com/v1/things?page=2&access_token=***&q=cat")
    }

    @Test("matching is case-insensitive")
    func caseInsensitive() {
        let redacted = Redactor().redact(url: url("https://api.example.com/x?ApiKey=SECRET&Signature=zzz"))
        #expect(!redacted.contains("SECRET"))
        #expect(!redacted.contains("zzz"))
    }

    @Test("configured names are masked on top of the defaults")
    func customNames() {
        let redacted = Redactor(redactedQueryItems: ["session"]).redact(
            url: url("https://a.example.com/x?session=s3cr3t"))
        #expect(redacted == "https://a.example.com/x?session=***")
    }

    @Test("a password in the userinfo is masked")
    func userinfoPassword() {
        let redacted = Redactor().redact(url: url("https://user:hunter2@api.example.com/x"))
        #expect(!redacted.contains("hunter2"))
    }

    @Test("a URL with no query comes back unchanged")
    func noQuery() {
        #expect(Redactor().redact(url: url("https://api.example.com/v1/things")) == "https://api.example.com/v1/things")
    }

    @Test("a default client never logs the API key it sends in the query")
    func apiKeyAuthNotLogged() async throws {
        let logger = CapturingLogger()
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.logger = logger
        config.environment.logLevel = .basic
        config.authorization = APIKeyAuth(query: "sessionkey", value: "SECRET123")
        let transport = MockNetworkTransport(default: .json(Data(#"{"v":"ok"}"#.utf8)))
        let client = NetworkClient(configuration: config, transport: transport)

        _ = try await client.request(SecureEndpoint())

        #expect(transport.recordedRequests.first?.url?.absoluteString.contains("SECRET123") == true)
        #expect(!logger.lines.contains { $0.contains("SECRET123") })
        #expect(logger.lines.contains { $0.contains("sessionkey=***") })
    }
}
