import Foundation

/// Common server behaviors for ``MockNetworkTransport``, as a one-liner.
///
/// ```swift
/// let transport = MockScenario.tokenExpired.transport(then: .json(userJSON))
/// ```
public enum MockScenario: Sendable {
    /// Every request succeeds with 200 and `body`.
    case happyPath(body: Data)
    /// The first request 401s, the rest succeed with `body` (drives the refresh flow).
    case tokenExpired(body: Data)
    /// Every request fails with `.noInternet`.
    case offline
    /// Every request 429s with `Retry-After: 1`.
    case rateLimited
    /// Every request 500s.
    case serverErrors

    /// Builds a transport pre-configured for this scenario. `then` outcomes are appended to the FIFO
    /// queue (used after the scenario's scripted part).
    public func transport(then extra: MockNetworkTransport.Outcome...) -> MockNetworkTransport {
        let transport: MockNetworkTransport
        switch self {
        case .happyPath(let body):
            transport = MockNetworkTransport(default: .json(body))
        case .tokenExpired(let body):
            transport = MockNetworkTransport(default: .json(body))
            transport.enqueue(.status(401, body: Data(#"{"error":"token_expired"}"#.utf8)))
        case .offline:
            transport = MockNetworkTransport(default: .failure(.noInternet))
        case .rateLimited:
            transport = MockNetworkTransport(default: .status(429, headers: ["Retry-After": "1"]))
        case .serverErrors:
            transport = MockNetworkTransport(default: .status(500))
        }
        if !extra.isEmpty { transport.enqueue(contentsOf: extra) }
        return transport
    }
}

extension MockNetworkTransport {
    @discardableResult
    func enqueue(contentsOf outcomes: [Outcome]) -> Self {
        for outcome in outcomes { enqueue(outcome) }
        return self
    }
}
