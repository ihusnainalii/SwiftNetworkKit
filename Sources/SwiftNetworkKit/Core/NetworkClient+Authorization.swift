import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension NetworkClient {

    /// Applies the endpoint's authentication to `request`, reading the token through the
    /// ``TokenManager`` when auto-refresh is on (so an expiring token is refreshed first), or straight
    /// from storage otherwise.
    func authorize<E: Endpoint>(_ request: inout URLRequest, for endpoint: E) async throws {
        let strategy: any AuthStrategy
        switch endpoint.authentication {
        case .none:
            return
        case .required:
            strategy = configuration.authorization
        case .custom(let custom):
            strategy = custom
        }

        let token: String?
        if let tokenManager {
            token = await tokenManager.tokenForOutgoingRequest()
        } else {
            token = try? await configuration.tokenStorage.accessToken()
        }
        try await strategy.authorize(&request, token: token)
    }
}
