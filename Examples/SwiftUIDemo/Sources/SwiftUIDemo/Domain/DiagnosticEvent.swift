import Foundation

/// A step in a scripted diagnostic scenario.
struct DiagnosticEvent: Sendable, Identifiable {
    enum Kind: Sendable { case info, success, warning, failure }
    let id = UUID()
    let message: String
    let kind: Kind
}
