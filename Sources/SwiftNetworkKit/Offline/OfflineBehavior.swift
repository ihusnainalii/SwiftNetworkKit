import Foundation

/// What an ``Endpoint`` does when it's sent while the device is offline.
public enum OfflineBehavior: Sendable, Hashable {
    /// Fail the request with ``NetworkError/noInternet`` (the default).
    case fail
    /// Persist the request and replay it FIFO when connectivity returns. The caller gets
    /// ``NetworkError/offlineQueued(_:)`` immediately; the replay result arrives on
    /// ``NetworkClient/offlineReplayEvents()``.
    ///
    /// A replayed request is sent exactly as it was archived: it keeps the `Authorization` header it
    /// had, with no token-refresh hop, so one that outlives its token replays as a 401 (delivered as
    /// `.replayed` with that status). There is also no idempotency guard, so only queue requests that
    /// are safe to send twice, or that the server de-duplicates.
    ///
    /// `expiresAfter` drops the request if it hasn't been replayed within that many seconds.
    /// Multipart bodies can't be persisted, so a multipart endpoint always falls back to `.fail`.
    case queue(expiresAfter: TimeInterval?)
}
