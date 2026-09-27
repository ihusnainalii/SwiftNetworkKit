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
/// `Sendable` has no runtime witness, so an arbitrary `any Error` cannot be checked for conformance in
/// general. The handful of concrete error types this package actually receives from Foundation and the
/// standard library (`URLError`, `DecodingError`, `EncodingError`) are known statically to conform,
/// though, so they are checked for by concrete type and passed through untouched, introspectable and
/// pattern-matchable by callers. Anything else is boxed by description.
func asSendableError(_ error: any Error) -> any Error & Sendable {
    if let boxed = error as? SendableErrorBox { return boxed }
    if let urlError = error as? URLError { return urlError }
    if let decodingError = error as? DecodingError { return decodingError }
    if let encodingError = error as? EncodingError { return encodingError }
    return SendableErrorBox(error)
}
