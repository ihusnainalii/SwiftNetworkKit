import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A byte-count update for an in-flight upload or download.
public struct ProgressEvent: Sendable, Hashable {
    /// Bytes transferred so far.
    public let completed: Int64
    /// Expected total, or a negative value when the server didn't say (`NSURLSessionTransferSizeUnknown`).
    public let total: Int64

    public init(completed: Int64, total: Int64) {
        self.completed = completed
        self.total = total
    }

    /// `completed / total` clamped to `0...1`, or `nil` when the total is unknown.
    public var fraction: Double? {
        guard total > 0 else { return nil }
        return min(1, max(0, Double(completed) / Double(total)))
    }
}
