import Foundation

/// What an ``Endpoint`` does when it's sent while the device is offline.
public enum OfflineBehavior: Sendable, Hashable {
    /// Fail the request with ``NetworkError/noInternet`` (the default).
    case fail
    /// Persist the request and replay it FIFO when connectivity returns. The caller gets
    /// ``NetworkError/offlineQueued(_:)`` immediately; the replay result arrives on
    /// ``NetworkClient/offlineReplayEvents()``.
    ///
    /// `expiresAfter` drops the request if it hasn't been replayed within that many seconds.
    /// Multipart bodies can't be persisted, so a multipart endpoint always falls back to `.fail`.
    case queue(expiresAfter: TimeInterval?)
}
