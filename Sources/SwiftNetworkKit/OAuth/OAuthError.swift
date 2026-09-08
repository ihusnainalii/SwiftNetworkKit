import Foundation

/// Why an OAuth step failed.
public enum OAuthError: Error, Sendable, Equatable {
    /// The redirect URL's `state` did not match the value passed to `authorizationURL`.
    case stateMismatch
    /// The redirect URL carried `error=<code>` instead of `code=<...>`.
    case authorizationDenied(String)
    /// No `code` query item in the redirect URL.
    case missingAuthorizationCode
    /// The token endpoint returned a non-2xx response.
    case tokenRequestFailed(status: Int, body: String?)
    /// The token endpoint's body was not a valid `OAuthTokenResponse`.
    case malformedTokenResponse
}
