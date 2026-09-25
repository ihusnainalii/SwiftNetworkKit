import Foundation

extension HTTPHeaders {

    /// A copy without the fields that carry credentials or session state (`Set-Cookie`,
    /// `Authorization`, and any names in `additional`), so they are never written into a cache entry,
    /// in memory or on disk. `additional` is matched case-insensitively.
    func removingCredentials(also additional: Set<String> = []) -> HTTPHeaders {
        let denied = Redactor.alwaysRedactedHeaders.union(additional.map { $0.lowercased() })
        var kept = HTTPHeaders()
        for element in self where !denied.contains(element.name.lowercased()) {
            kept[element.name] = element.value
        }
        return kept
    }
}
