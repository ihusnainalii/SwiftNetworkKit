import Foundation

/// A `Sendable` wrapper for an arbitrary error whose concrete type may not itself be `Sendable`.
///
/// Foundation's common errors (`URLError`, `DecodingError`, `EncodingError`) are already `Sendable`
/// and pass through untouched via ``asSendableError(_:)``; anything else is captured by description
/// so ``NetworkError`` can stay fully `Sendable` without an `@unchecked` escape hatch.
struct SendableErrorBox: Error, Sendable, CustomStringConvertible {
    let underlyingType: String
    let description: String

    init(_ error: any Error) {
        underlyingType = String(reflecting: type(of: error))
        description = String(describing: error)
    }
}

/// Wraps an arbitrary thrown error so it can be carried by the (fully `Sendable`) ``NetworkError``.
///
/// `Sendable` has no runtime witness, so an arbitrary `any Error` cannot be checked for conformance —
/// it is always boxed. Call sites that already hold a statically-`Sendable` error (e.g. `URLError`)
/// pass it to ``NetworkError`` directly and skip this.
func asSendableError(_ error: any Error) -> any Error & Sendable {
    (error as? SendableErrorBox) ?? SendableErrorBox(error)
}
