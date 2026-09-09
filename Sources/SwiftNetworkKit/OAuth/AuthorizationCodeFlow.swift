import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The OAuth 2.0 Authorization Code flow with PKCE — URL building and token exchange. It performs
/// **no UI**: the app presents ``authorizationURL(state:pkce:)`` (e.g. in `ASWebAuthenticationSession`),
/// captures the redirect, calls ``authorizationCode(fromRedirect:expectedState:)``, then
/// ``exchange(code:pkce:)``.
///
/// ```swift
/// let flow = AuthorizationCodeFlow(configuration: config)
/// let state = AuthorizationCodeFlow.makeState()
/// let pkce = PKCE()
/// // present flow.authorizationURL(state: state, pkce: pkce), get back `redirectURL`
/// let code = try flow.authorizationCode(fromRedirect: redirectURL, expectedState: state)
/// let tokens = try await flow.exchange(code: code, pkce: pkce)
/// ```
public struct AuthorizationCodeFlow: Sendable {

    public let configuration: OAuthConfiguration
    private let transport: any NetworkTransport

    public init(
        configuration: OAuthConfiguration,
        transport: (any NetworkTransport)? = nil
    ) {
        self.configuration = configuration
        #if os(WASI)
        guard let transport else { preconditionFailure("Pass `transport:` on WebAssembly.") }
        self.transport = transport
        #else
        self.transport = transport ?? URLSessionTransport()
        #endif
    }

    /// The RFC 6749 token response is a fixed wire format — decode it with plain keys, independent of
    /// the client's `JSONDecoder` configuration.
    private var decoder: JSONDecoder { JSONDecoder() }

    /// A fresh, opaque `state` value to guard against CSRF on the redirect.
    public static func makeState() -> String {
        Base64URL.encode(Data((0..<24).map { _ in UInt8.random(in: .min ... .max) }))
    }

    // MARK: Authorization URL

    public func authorizationURL(state: String, pkce: PKCE) -> URL {
        var components = URLComponents(url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        var items = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: configuration.clientID),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectURI),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: pkce.challenge),
            URLQueryItem(name: "code_challenge_method", value: pkce.method),
        ]
        if !configuration.scopes.isEmpty {
            items.append(URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")))
        }
        for (key, value) in configuration.additionalAuthParameters.sorted(by: { $0.key < $1.key }) {
            items.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = (components.queryItems ?? []) + items
        return components.url!
    }

    /// Validates the provider's redirect and returns the authorization `code`.
    public func authorizationCode(fromRedirect url: URL, expectedState: String) throws -> String {
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        func value(_ name: String) -> String? { items.first { $0.name == name }?.value }

        guard value("state") == expectedState else { throw OAuthError.stateMismatch }
        if let error = value("error") { throw OAuthError.authorizationDenied(error) }
        guard let code = value("code") else { throw OAuthError.missingAuthorizationCode }
        return code
    }

    // MARK: Token exchange

    public func exchange(code: String, pkce: PKCE) async throws -> OAuthTokenResponse {
        try await tokenRequest([
            "grant_type": "authorization_code",
            "code": code,
            "redirect_uri": configuration.redirectURI,
            "client_id": configuration.clientID,
            "code_verifier": pkce.verifier,
        ])
    }

    public func refresh(refreshToken: String) async throws -> OAuthTokenResponse {
        try await tokenRequest([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": configuration.clientID,
        ])
    }

    // MARK: - Internals

    private func tokenRequest(_ fields: [String: String]) async throws -> OAuthTokenResponse {
        var fields = fields
        if let secret = configuration.clientSecret { fields["client_secret"] = secret }

        var request = URLRequest(url: configuration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.httpBody = Self.formEncoded(fields)

        let data: Data
        let response: HTTPURLResponse
        do {
            (data, response) = try await transport.data(for: request)
        } catch {
            throw NetworkError.normalize(error)
        }

        guard (200..<300).contains(response.statusCode) else {
            throw OAuthError.tokenRequestFailed(status: response.statusCode, body: String(data: data, encoding: .utf8))
        }
        guard let token = try? decoder.decode(OAuthTokenResponse.self, from: data) else {
            throw OAuthError.malformedTokenResponse
        }
        return token
    }

    static func formEncoded(_ fields: [String: String]) -> Data {
        // application/x-www-form-urlencoded: only RFC 3986 unreserved characters pass through.
        let allowed = CharacterSet(
            charactersIn:
                "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
        let pairs = fields.sorted { $0.key < $1.key }.map { key, value in
            let k = key.addingPercentEncoding(withAllowedCharacters: allowed) ?? key
            let v = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
            return "\(k)=\(v)"
        }
        return Data(pairs.joined(separator: "&").utf8)
    }
}
