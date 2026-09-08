import Foundation

/// Whether — and how — a request needs authentication applied.
public enum AuthRequirement: Sendable {
    /// No authentication.
    case none
    /// Apply the client's configured ``AuthStrategy``, refreshing the token on a 401.
    case required
    /// Apply a specific strategy for this endpoint (still 401-refresh aware).
    case custom(any AuthStrategy)

    /// `true` for `.required` and `.custom`.
    public var isAuthenticated: Bool {
        switch self {
        case .none: false
        case .required, .custom: true
        }
    }
}

extension AuthRequirement: Equatable {
    /// Compares only the well-known cases; two `.custom` values are never considered equal
    /// (strategies aren't `Equatable`).
    public static func == (lhs: AuthRequirement, rhs: AuthRequirement) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none), (.required, .required): true
        default: false
        }
    }
}
