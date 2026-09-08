import Foundation

/// Persistence for the offline request queue. Built-in: ``FileOfflineStore``; tests use
/// `InMemoryOfflineStore`.
public protocol OfflineStore: Sendable {
    func append(_ request: PersistedRequest) async
    /// All queued requests, oldest first.
    func all() async -> [PersistedRequest]
    func update(_ request: PersistedRequest) async
    func remove(_ id: RequestID) async
    func removeAll() async
}
