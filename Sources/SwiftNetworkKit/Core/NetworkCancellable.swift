/// A handle for cancelling an in-flight request started via a completion-handler call.
public struct NetworkCancellable: Sendable {
    private let _cancel: @Sendable () -> Void

    public init(_ cancel: @escaping @Sendable () -> Void) {
        _cancel = cancel
    }

    /// Cancels the underlying `Task`. Safe to call more than once.
    public func cancel() {
        _cancel()
    }
}
