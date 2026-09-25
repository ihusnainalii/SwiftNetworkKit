import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

extension NetworkClient {

    /// Refreshes a stale cache entry without making the caller wait. The refresh runs through the
    /// concurrency queue at low priority like any other request, and a failure is logged instead of
    /// discarded, so a permanently failing endpoint does not serve stale data with no sign of it.
    func revalidateInBackground<E: Endpoint, T: Sendable>(
        _ endpoint: E,
        decode: @escaping @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> T
    ) {
        Task.detached { [self] in
            do {
                try await queued(priority: .low, skipQueue: endpoint.skipRequestQueue) {
                    _ = try await self.execute(
                        endpoint, requestID: RequestID(), interceptorRetries: 0,
                        bypassCacheRead: true, decode: decode
                    )
                }
            } catch {
                let code = NetworkError.normalize(error).code.rawValue
                emit(["\u{2190} background revalidation failed: \(code)"], level: .error)
            }
        }
    }
}
