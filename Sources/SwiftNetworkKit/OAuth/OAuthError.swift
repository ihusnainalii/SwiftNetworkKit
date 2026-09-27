import Foundation

/// Why an OAuth step failed.
public enum OAuthError: Error, Sendable, Equatable {
    /// The redirect URL's `state` did not match the value passed to `authorizationURL`.
    case stateMismatch
    /// The redirect URL carried `error=<code>` instead of `code=<...>`.
    case authorizationDenied(String)
    /// No `code` query item in the redirect URL.
    case missingAuthorizationCode
    /// The token endpoint returned a non-2xx response. `body` has sensitive JSON keys (`access_token`,
    /// `refresh_token`, ...) masked, and is a byte count for a body that is not JSON.
    case tokenRequestFailed(status: Int, body: String?)
    /// The token endpoint's body was not a valid `OAuthTokenResponse`.
    case malformedTokenResponse
    /// `OAuthConfiguration.authorizationEndpoint` could not be turned into a request URL, either
    /// because it isn't decomposable into `URLComponents` or because appending the required query
    /// items produced an invalid URL. Both are extremely unlikely for a URL the app already
    /// constructed, but Foundation does not guarantee they can't happen.
    case invalidAuthorizationURL
}
