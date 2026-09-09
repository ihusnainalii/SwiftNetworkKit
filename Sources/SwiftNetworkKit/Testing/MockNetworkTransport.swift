import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// An in-memory ``NetworkTransport`` for unit tests. Shipped in the library so consuming apps can
/// use it too.
///
/// Two ways to script it:
///
/// - **FIFO queue** — `enqueue(outcome, outcome, …)` returns outcomes in order, then `defaultOutcome`.
///   Simple, but ambiguous when several requests run concurrently.
/// - **Matcher rules** — `stub(method:pathContains:with:)` (or `stub(matching:with:)`) attaches a
///   response to requests that match, regardless of order. Rules win over the queue; each rule can
///   itself hold a scripted sequence (e.g. `[.status(401), .json(...)]`).
///
/// Every request is recorded. A non-zero `latency` makes `data(for:)` suspend (and thus throw
/// `CancellationError` if the surrounding `Task` is cancelled). See `MockScenario` for presets.
public final class MockNetworkTransport: NetworkTransport, @unchecked Sendable {

    public enum Outcome: Sendable {
        case success(status: Int, headers: HTTPHeaders, body: Data)
        case failure(NetworkError)

        public static func json(_ body: Data, status: Int = 200, headers: HTTPHeaders = [:]) -> Outcome {
            var headers = headers
            if headers["Content-Type"] == nil { headers["Content-Type"] = "application/json" }
            return .success(status: status, headers: headers, body: body)
        }

        /// A bare status-code response — handy for scripting retry sequences (`503, 503, 200`).
        public static func status(_ code: Int, headers: HTTPHeaders = [:], body: Data = Data()) -> Outcome {
            .success(status: code, headers: headers, body: body)
        }
    }

    /// A matcher rule: requests satisfying `matches` get `outcomes` (a scripted sequence; the last
    /// one repeats once exhausted).
    struct Rule: @unchecked Sendable {
        let matches: (URLRequest) -> Bool
        var outcomes: [Outcome]
    }

    private let lock = NSLock()
    private var queue: [Outcome] = []
    private var rules: [Rule] = []
    private var recorded: [URLRequest] = []
    private let defaultOutcome: Outcome
    private let latency: Duration

    public init(
        default defaultOutcome: Outcome = .success(status: 200, headers: [:], body: Data()),
        latency: Duration = .zero
    ) {
        self.defaultOutcome = defaultOutcome
        self.latency = latency
    }

    /// Requests captured so far, in order.
    public var recordedRequests: [URLRequest] {
        lock.lock()
        defer { lock.unlock() }
        return recorded
    }

    /// Number of requests received.
    public var requestCount: Int {
        lock.lock()
        defer { lock.unlock() }
        return recorded.count
    }

    @discardableResult
    public func enqueue(_ outcomes: Outcome...) -> Self {
        lock.lock()
        defer { lock.unlock() }
        queue.append(contentsOf: outcomes)
        return self
    }

    /// Enqueues a JSON success by encoding `value`.
    @discardableResult
    public func enqueueJSON(_ value: some Encodable, status: Int = 200) -> Self {
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        return enqueue(.json(data, status: status))
    }

    /// Responds to requests matching `predicate` with `outcomes` (a scripted sequence; the last one
    /// repeats). Rules are checked before the FIFO queue, first-registered first.
    @discardableResult
    public func stub(
        matching predicate: @escaping @Sendable (URLRequest) -> Bool,
        with outcomes: Outcome...
    ) -> Self {
        lock.lock()
        defer { lock.unlock() }
        rules.append(Rule(matches: predicate, outcomes: outcomes))
        return self
    }

    /// Responds to requests whose method and/or path substring match.
    @discardableResult
    public func stub(
        method: HTTPMethod? = nil,
        pathContains: String? = nil,
        with outcomes: Outcome...
    ) -> Self {
        let rule = Rule(
            matches: { request in
                if let method, request.httpMethod?.uppercased() != method.rawValue { return false }
                if let pathContains, !(request.url?.path.contains(pathContains) ?? false) { return false }
                return true
            },
            outcomes: outcomes
        )
        lock.lock()
        defer { lock.unlock() }
        rules.append(rule)
        return self
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let outcome: Outcome = {
            lock.lock()
            defer { lock.unlock() }
            recorded.append(request)
            if let index = rules.firstIndex(where: { $0.matches(request) }) {
                let outcomes = rules[index].outcomes
                if outcomes.count > 1 { rules[index].outcomes.removeFirst() }
                return outcomes.first ?? defaultOutcome
            }
            return queue.isEmpty ? defaultOutcome : queue.removeFirst()
        }()

        if latency > .zero {
            try await Task.sleep(for: latency)
        }

        switch outcome {
        case .failure(let error):
            throw error
        case .success(let status, let headers, let body):
            let url = request.url ?? URL(string: "https://mock.invalid")!
            let response = HTTPURLResponse(
                url: url,
                statusCode: status,
                httpVersion: "HTTP/1.1",
                headerFields: headers.dictionary
            )!
            return (body, response)
        }
    }
}
