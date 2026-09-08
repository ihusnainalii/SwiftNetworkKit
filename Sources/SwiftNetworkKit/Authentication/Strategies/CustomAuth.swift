import Foundation

/// An arbitrary app-supplied authentication closure.
public struct CustomAuth: AuthStrategy {
    private let apply: @Sendable (_ request: inout URLRequest, _ token: String?) async throws -> Void

    public init(_ apply: @escaping @Sendable (_ request: inout URLRequest, _ token: String?) async throws -> Void) {
        self.apply = apply
    }

    public func authorize(_ request: inout URLRequest, token: String?) async throws {
        try await apply(&request, token)
    }
}
