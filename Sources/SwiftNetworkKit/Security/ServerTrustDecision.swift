#if canImport(Security)
import Security

/// The outcome of evaluating one server-trust challenge against the resolved pinning rules.
///
/// The distinction between ``pinned`` and ``notPinned`` matters: answering a challenge with
/// `.useCredential` tells `URLSession` to skip its own chain / hostname / expiry evaluation, so it
/// is only safe when a pin actually matched. A host the configuration does not cover must fall back
/// to `.performDefaultHandling` — pinning must never *weaken* TLS for a host it was not asked to pin.
public enum ServerTrustDecision: Sendable, Equatable {
    /// A configured pin matched (and, unless disabled, the system chain evaluation passed).
    /// Accept the server with its own credential.
    case pinned
    /// This host has no pins, or the evaluator is in record-only mode. Let `URLSession` run its
    /// normal system evaluation.
    case notPinned
    /// Pins are configured for this host and none matched (or the system chain failed). Reject.
    case rejected(NetworkError)

    public static func == (lhs: ServerTrustDecision, rhs: ServerTrustDecision) -> Bool {
        switch (lhs, rhs) {
        case (.pinned, .pinned), (.notPinned, .notPinned): true
        case (.rejected(let l), .rejected(let r)): l.code == r.code
        default: false
        }
    }
}
#endif
