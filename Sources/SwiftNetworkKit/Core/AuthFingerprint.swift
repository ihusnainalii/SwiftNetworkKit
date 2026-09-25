import Foundation

/// Identifies *whose* credentials a request carries, without holding the credential itself.
///
/// Cache and dedup keys include it so a response fetched with one account's token is never served to a
/// request made with another's. It is a truncated SHA-256 of the `Authorization` value, so it changes
/// whenever the token does (a token refresh starts a fresh cache namespace).
enum AuthFingerprint {

    /// `""` for an unauthenticated request, otherwise ` auth:<32 hex chars>`.
    static func suffix(for authorization: String?) -> String {
        guard let authorization else { return "" }
        return " auth:" + SHA256Hex.string(authorization).prefix(32)
    }
}
