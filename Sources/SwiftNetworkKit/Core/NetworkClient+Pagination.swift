import Foundation

extension NetworkClient {

    /// Streams a paginated endpoint page by page. Each element is one page's items; the stream
    /// finishes when ``PaginatedEndpoint/nextPage(after:)`` returns `nil`, and honors task
    /// cancellation.
    ///
    /// - Parameter maxPages: a safety cap against a server that always returns a next page.
    ///   Exceeding it finishes the stream (with a `.error`-level log line) rather than looping forever.
    public func paginate<E: PaginatedEndpoint>(
        _ endpoint: E,
        maxPages: Int = 1000
    ) -> AsyncThrowingStream<[E.Item], any Error> {
        AsyncThrowingStream { continuation in
            let task = Task {
                var current: E? = endpoint
                var pageCount = 0
                do {
                    while let page = current {
                        if Task.isCancelled { break }
                        if pageCount >= maxPages {
                            emit(
                                ["\u{2190} pagination stopped at maxPages=\(maxPages) for \(page.path)"], level: .error)
                            break
                        }
                        let response = try await request(page)
                        continuation.yield(page.items(from: response))
                        pageCount += 1
                        current = page.nextPage(after: response)
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
            continuation.onTermination = { _ in task.cancel() }
        }
    }

    /// Drains ``paginate(_:maxPages:)`` into one array, optionally stopping once `max` items are
    /// collected.
    public func collectAll<E: PaginatedEndpoint>(
        _ endpoint: E,
        max: Int? = nil
    ) async throws -> [E.Item] {
        var all: [E.Item] = []
        for try await page in paginate(endpoint) {
            all.append(contentsOf: page)
            if let max, all.count >= max { return Array(all.prefix(max)) }
        }
        return all
    }
}
