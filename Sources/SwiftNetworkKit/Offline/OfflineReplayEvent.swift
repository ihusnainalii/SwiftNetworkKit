import Foundation

/// What happened to a queued request when connectivity returned. Observe the stream with
/// ``NetworkClient/offlineReplayEvents()``.
public enum OfflineReplayEvent: Sendable {
    /// The request was re-sent and the server responded with `statusCode`.
    case replayed(RequestID, statusCode: Int)
    /// The re-send failed; the request stays queued for the next reconnect.
    case failed(RequestID, NetworkError)
    /// The request expired before it could be replayed and was dropped.
    case expired(RequestID)
}
