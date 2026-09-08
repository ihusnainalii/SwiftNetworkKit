import Foundation

/// `Authorization: Bearer <token>`. No-op when `token` is `nil`.
public struct BearerAuth: AuthStrategy {
    public init() {}

    public func authorize(_ request: inout URLRequest, token: String?) async throws {
        guard let token else { return }
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
}
