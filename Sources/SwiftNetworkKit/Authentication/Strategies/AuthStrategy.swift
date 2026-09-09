import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Applies authentication to an outgoing request.
///
/// The `token` argument is the current access token from the client's ``TokenStorage`` (via
/// ``TokenManager``), or `nil` when none is available — strategies that don't use a bearer token
/// (API key, basic) simply ignore it.
public protocol AuthStrategy: Sendable {
    func authorize(_ request: inout URLRequest, token: String?) async throws
}
