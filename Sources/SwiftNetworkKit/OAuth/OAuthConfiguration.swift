import Foundation

/// Everything ``AuthorizationCodeFlow`` needs to talk to an OAuth 2.0 provider.
///
/// Provider shapes (fill these in from the provider's docs):
/// - **Google**: `authorizationEndpoint` `https://accounts.google.com/o/oauth2/v2/auth`,
///   `tokenEndpoint` `https://oauth2.googleapis.com/token`.
/// - **Auth0**: `https://<tenant>/authorize` and `https://<tenant>/oauth/token`.
/// - **Okta**: `https://<org>/oauth2/default/v1/authorize` and `.../v1/token`.
public struct OAuthConfiguration: Sendable, Hashable {
    public var authorizationEndpoint: URL
    public var tokenEndpoint: URL
    public var clientID: String
    /// Only for confidential clients. Native apps should use PKCE and leave this `nil`.
    public var clientSecret: String?
    public var redirectURI: String
    public var scopes: [String]
    /// Extra query items on the authorization URL (`prompt`, `audience`, `login_hint`, …).
    public var additionalAuthParameters: [String: String]

    public init(
        authorizationEndpoint: URL,
        tokenEndpoint: URL,
        clientID: String,
        clientSecret: String? = nil,
        redirectURI: String,
        scopes: [String] = [],
        additionalAuthParameters: [String: String] = [:]
    ) {
        self.authorizationEndpoint = authorizationEndpoint
        self.tokenEndpoint = tokenEndpoint
        self.clientID = clientID
        self.clientSecret = clientSecret
        self.redirectURI = redirectURI
        self.scopes = scopes
        self.additionalAuthParameters = additionalAuthParameters
    }
}
