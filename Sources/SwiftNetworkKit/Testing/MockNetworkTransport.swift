import Foundation

/// An in-memory ``NetworkTransport`` for unit tests. Shipped in the library so consuming apps can
/// use it too.
///
/// Enqueue outcomes in the order requests will be made; when the queue is empty the `defaultOutcome`
/// is returned. Every request is recorded. A non-zero `latency` makes `data(for:)` suspend (and thus
/// throw `CancellationError` if the surrounding `Task` is cancelled).
///
/// Milestone M13 expands this into matcher-based rules and scenario presets.
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

    private let lock = NSLock()
    private var queue: [Outcome] = []
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
        lock.lock(); defer { lock.unlock() }
        return recorded
    }

    /// Number of requests received.
    public var requestCount: Int {
        lock.lock(); defer { lock.unlock() }
        return recorded.count
    }

    @discardableResult
    public func enqueue(_ outcomes: Outcome...) -> Self {
        lock.lock(); defer { lock.unlock() }
        queue.append(contentsOf: outcomes)
        return self
    }

    /// Enqueues a JSON success by encoding `value`.
    @discardableResult
    public func enqueueJSON(_ value: some Encodable, status: Int = 200) -> Self {
        let data = (try? JSONEncoder().encode(value)) ?? Data()
        return enqueue(.json(data, status: status))
    }

    public func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
        let outcome: Outcome = {
            lock.lock(); defer { lock.unlock() }
            recorded.append(request)
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
