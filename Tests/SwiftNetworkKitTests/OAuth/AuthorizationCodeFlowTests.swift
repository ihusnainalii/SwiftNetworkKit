import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("AuthorizationCodeFlow")
struct AuthorizationCodeFlowTests {

    private func config() -> OAuthConfiguration {
        OAuthConfiguration(
            authorizationEndpoint: URL(string: "https://auth.example.com/authorize")!,
            tokenEndpoint: URL(string: "https://auth.example.com/token")!,
            clientID: "client-123",
            redirectURI: "myapp://callback",
            scopes: ["openid", "profile"],
            additionalAuthParameters: ["prompt": "consent"]
        )
    }

    @Test("authorization URL carries every required parameter")
    func authorizationURL() {
        let flow = AuthorizationCodeFlow(configuration: config())
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")
        let url = flow.authorizationURL(state: "xyz", pkce: pkce)

        let items = Dictionary(
            uniqueKeysWithValues: URLComponents(url: url, resolvingAgainstBaseURL: false)!
                .queryItems!.map { ($0.name, $0.value ?? "") }
        )
        #expect(items["response_type"] == "code")
        #expect(items["client_id"] == "client-123")
        #expect(items["redirect_uri"] == "myapp://callback")
        #expect(items["state"] == "xyz")
        #expect(items["code_challenge"] == "E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM")
        #expect(items["code_challenge_method"] == "S256")
        #expect(items["scope"] == "openid profile")
        #expect(items["prompt"] == "consent")
    }

    @Test("redirect validation returns the code, rejects a bad state, surfaces error=")
    func redirectValidation() throws {
        let flow = AuthorizationCodeFlow(configuration: config())

        let ok = URL(string: "myapp://callback?code=abc123&state=xyz")!
        #expect(try flow.authorizationCode(fromRedirect: ok, expectedState: "xyz") == "abc123")

        #expect(throws: OAuthError.stateMismatch) {
            try flow.authorizationCode(fromRedirect: ok, expectedState: "different")
        }
        let denied = URL(string: "myapp://callback?error=access_denied&state=xyz")!
        #expect(throws: OAuthError.authorizationDenied("access_denied")) {
            try flow.authorizationCode(fromRedirect: denied, expectedState: "xyz")
        }
    }

    @Test("exchange POSTs the correct form fields and decodes the token")
    func exchange() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"""
        {"access_token":"AT","refresh_token":"RT","expires_in":3600,"token_type":"Bearer","scope":"openid"}
        """#.utf8)))
        let flow = AuthorizationCodeFlow(configuration: config(), transport: transport)
        let pkce = PKCE(verifier: "dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk")

        let token = try await flow.exchange(code: "the-code", pkce: pkce)

        #expect(token.accessToken == "AT")
        #expect(token.refreshToken == "RT")
        #expect(token.expiresIn == 3600)
        #expect(token.expiryDate != nil)

        let body = String(data: transport.recordedRequests.first?.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("grant_type=authorization_code"))
        #expect(body.contains("code=the-code"))
        #expect(body.contains("code_verifier=dBjftJeZ4CVP-mB92K27uhbUJU1p1r_wW1gFWFOEjXk"))
        #expect(body.contains("client_id=client-123"))
        #expect(body.contains("redirect_uri=myapp%3A%2F%2Fcallback"))
    }

    @Test("refresh POSTs grant_type=refresh_token")
    func refresh() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"access_token":"AT2","token_type":"Bearer","expires_in":60}"#.utf8)))
        let flow = AuthorizationCodeFlow(configuration: config(), transport: transport)

        let token = try await flow.refresh(refreshToken: "RT")
        #expect(token.accessToken == "AT2")

        let body = String(data: transport.recordedRequests.first?.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("grant_type=refresh_token"))
        #expect(body.contains("refresh_token=RT"))
    }

    @Test("a non-2xx token response throws OAuthError.tokenRequestFailed")
    func tokenError() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(400, body: Data(#"{"error":"invalid_grant"}"#.utf8)))
        let flow = AuthorizationCodeFlow(configuration: config(), transport: transport)

        await #expect(throws: OAuthError.self) {
            _ = try await flow.refresh(refreshToken: "stale")
        }
    }

    @Test("client secret is included when set")
    func clientSecret() async throws {
        var c = config()
        c.clientSecret = "shh"
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"access_token":"AT","token_type":"Bearer"}"#.utf8)))
        _ = try await AuthorizationCodeFlow(configuration: c, transport: transport).refresh(refreshToken: "RT")
        let body = String(data: transport.recordedRequests.first?.httpBody ?? Data(), encoding: .utf8) ?? ""
        #expect(body.contains("client_secret=shh"))
    }

    @Test("tokenManagerRefreshHandler exchanges the stored refresh token")
    func refreshHandlerIntegration() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"access_token":"fresh","refresh_token":"RT2","token_type":"Bearer","expires_in":3600}"#.utf8)))
        let flow = AuthorizationCodeFlow(configuration: config(), transport: transport)
        let storage = InMemoryTokenStorage(seed: TokenPair(accessToken: "old", refreshToken: "RT"))

        let pair = try await flow.tokenManagerRefreshHandler()(storage)
        #expect(pair.accessToken == "fresh")
        #expect(pair.refreshToken == "RT2")
        #expect(pair.expiresAt != nil)
    }
}
