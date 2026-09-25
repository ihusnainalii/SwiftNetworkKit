import Foundation

/// What happened to a queued request when connectivity returned. Observe the stream with
/// ``NetworkClient/offlineReplayEvents()``.
public enum OfflineReplayEvent: Sendable {
    /// The request was re-sent and the server responded with `statusCode`.
    case replayed(RequestID, statusCode: Int)
    /// The re-send failed. The request stays queued for the next reconnect, unless it can no longer be
    /// rebuilt or has failed too many times, in which case it is dropped.
    case failed(RequestID, NetworkError)
    /// The request expired before it could be replayed and was dropped.
    case expired(RequestID)
}
