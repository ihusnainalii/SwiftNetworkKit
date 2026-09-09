import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import SwiftNetworkKit

@Suite("AuthStrategy")
struct AuthStrategyTests {

    private func request() -> URLRequest {
        URLRequest(url: URL(string: "https://api.example.com/me?x=1")!)
    }

    @Test("BearerAuth sets the Authorization header, no-op on nil token")
    func bearer() async throws {
        var authorized = request()
        try await BearerAuth().authorize(&authorized, token: "abc123")
        #expect(authorized.value(forHTTPHeaderField: "Authorization") == "Bearer abc123")

        var unauthenticated = request()
        try await BearerAuth().authorize(&unauthenticated, token: nil)
        #expect(unauthenticated.value(forHTTPHeaderField: "Authorization") == nil)
    }

    @Test("APIKeyAuth header placement")
    func apiKeyHeader() async throws {
        var req = request()
        try await APIKeyAuth(header: "X-API-Key", value: "secret").authorize(&req, token: nil)
        #expect(req.value(forHTTPHeaderField: "X-API-Key") == "secret")
    }

    @Test("APIKeyAuth query placement appends the item")
    func apiKeyQuery() async throws {
        var req = request()
        try await APIKeyAuth(query: "api_key", value: "secret").authorize(&req, token: nil)
        let query = req.url?.query ?? ""
        #expect(query.contains("x=1"))
        #expect(query.contains("api_key=secret"))
    }

    @Test("BasicAuth base64-encodes credentials")
    func basic() async throws {
        var req = request()
        try await BasicAuth(username: "user", password: "pass").authorize(&req, token: nil)
        let expected = "Basic " + Data("user:pass".utf8).base64EncodedString()
        #expect(req.value(forHTTPHeaderField: "Authorization") == expected)
    }

    @Test("CustomAuth runs the supplied closure")
    func custom() async throws {
        var req = request()
        let strategy = CustomAuth { request, token in
            request.setValue(token ?? "anon", forHTTPHeaderField: "X-User")
        }
        try await strategy.authorize(&req, token: "u42")
        #expect(req.value(forHTTPHeaderField: "X-User") == "u42")
    }
}
