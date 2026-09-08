import Foundation

extension NetworkClient {

    /// Runs two endpoints in parallel, returning both responses. Throws if either fails.
    /// (Concurrency is bounded by ``NetworkConfiguration/maxConcurrentRequests`` like any request.)
    public func zip<A: Endpoint, B: Endpoint>(_ a: A, _ b: B) async throws -> (A.Response, B.Response) {
        async let ra = request(a)
        async let rb = request(b)
        return try await (ra, rb)
    }

    /// Runs three endpoints in parallel, returning all three responses.
    public func zip<A: Endpoint, B: Endpoint, C: Endpoint>(
        _ a: A, _ b: B, _ c: C
    ) async throws -> (A.Response, B.Response, C.Response) {
        async let ra = request(a)
        async let rb = request(b)
        async let rc = request(c)
        return try await (ra, rb, rc)
    }

    /// Runs many same-typed endpoints in parallel and returns a result per input, in order. One
    /// failure does not cancel the others.
    public func batch<E: Endpoint>(_ endpoints: [E]) async -> [Result<E.Response, NetworkError>] {
        guard !endpoints.isEmpty else { return [] }
        return await withTaskGroup(of: (Int, Result<E.Response, NetworkError>).self) { group in
            for (index, endpoint) in endpoints.enumerated() {
                group.addTask {
                    do {
                        return (index, .success(try await self.request(endpoint)))
                    } catch {
                        return (index, .failure(NetworkError.normalize(error)))
                    }
                }
            }
            var results = [Result<E.Response, NetworkError>?](repeating: nil, count: endpoints.count)
            for await (index, result) in group { results[index] = result }
            return results.compactMap { $0 }
        }
    }
}
