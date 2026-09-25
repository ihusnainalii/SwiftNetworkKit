import Foundation

/// Two callers shared a dedup key but asked for different result types. The key is derived from the
/// endpoint, so this means two endpoint types produce the same method + URL + credentials.
struct DeduplicationTypeMismatch: Error, Sendable, CustomStringConvertible {
    let expected: String
    let actual: String

    var description: String {
        "Deduplicated request returned \(actual) but \(expected) was expected; two endpoint types share one key"
    }
}
