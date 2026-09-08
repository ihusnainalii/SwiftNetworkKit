import Foundation

/// A process-unique identifier for one logical request (survives auth-refresh retries).
///
/// Introduced here for ``TokenManager``'s per-request refresh guard; the request registry and
/// cancellation APIs (M9) build on the same type.
public struct RequestID: Hashable, Sendable, CustomStringConvertible {
    public let rawValue: UUID

    public init(rawValue: UUID = UUID()) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue.uuidString }
}
