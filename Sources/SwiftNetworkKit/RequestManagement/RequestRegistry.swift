import Foundation

/// Tracks in-flight requests by ``RequestID`` so they can be cancelled by id or all at once.
actor RequestRegistry {

    private var cancellers: [RequestID: @Sendable () -> Void] = [:]

    func register(_ id: RequestID, cancel: @escaping @Sendable () -> Void) {
        cancellers[id] = cancel
    }

    func deregister(_ id: RequestID) {
        cancellers[id] = nil
    }

    func cancel(_ id: RequestID) {
        cancellers[id]?()
        cancellers[id] = nil
    }

    func cancelAll() {
        for cancel in cancellers.values { cancel() }
        cancellers.removeAll()
    }

    /// Number of requests currently registered (test/inspection).
    var activeCount: Int { cancellers.count }
}
