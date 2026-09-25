import Foundation

/// Thrown by `collectAll` when the page cap stopped a listing that had more pages, so a partial array
/// is never mistaken for the whole collection.
struct PageLimitReached: Error, Sendable, CustomStringConvertible {
    let maxPages: Int

    var description: String {
        "Pagination stopped at maxPages=\(maxPages) with more pages available, so the result would be incomplete"
    }
}
