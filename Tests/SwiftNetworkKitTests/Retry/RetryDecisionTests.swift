import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("RetryDecision")
struct RetryDecisionTests {

    private func context(_ status: Int, headers: HTTPHeaders = [:]) -> ResponseContext {
        ResponseContext(
            statusCode: status,
            headers: headers,
            data: nil,
            request: URLRequest(url: URL(string: "https://api.example.com/x")!)
        )
    }

    private var noJitter: RetryPolicy {
        RetryPolicy(backoff: .exponential(), jitter: .none)
    }

    @Test("GET 503 retries with exponential backoff until the attempt budget is spent")
    func getServerErrorRetries() {
        let policy = noJitter // maxAttempts 3
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 1, error: .server(context(503))) == .retry(after: 0.5))
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 2, error: .server(context(503))) == .retry(after: 1))
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 3, error: .server(context(503))) == .stop)
    }

    @Test("POST 503 stops immediately (non-idempotent)")
    func postNotRetried() {
        #expect(RetryDecision.evaluate(policy: noJitter, method: .post, attempt: 1, error: .server(context(503))) == .stop)
    }

    @Test("POST retries when the policy opts non-idempotent methods in")
    func postRetriesWhenOptedIn() {
        var policy = noJitter
        policy.retryNonIdempotent = true
        #expect(RetryDecision.evaluate(policy: policy, method: .post, attempt: 1, error: .server(context(503))) == .retry(after: 0.5))
    }

    @Test("a non-retryable status code stops even for GET")
    func nonRetryableStatus() {
        // 501 is a 5xx (.server) but not in retryableStatusCodes.
        #expect(RetryDecision.evaluate(policy: noJitter, method: .get, attempt: 1, error: .server(context(501))) == .stop)
        #expect(RetryDecision.evaluate(policy: noJitter, method: .get, attempt: 1, error: .notFound(context(404))) == .stop)
    }

    @Test("429 honors Retry-After, capped, and falls back to backoff when disabled")
    func rateLimited() {
        let policy = noJitter
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 1, error: .rateLimited(retryAfter: 2, context(429))) == .retry(after: 2))

        var capped = policy
        capped.maxRetryAfterDelay = 5
        #expect(RetryDecision.evaluate(policy: capped, method: .get, attempt: 1, error: .rateLimited(retryAfter: 999, context(429))) == .retry(after: 5))

        var ignore = policy
        ignore.respectRetryAfter = false
        #expect(RetryDecision.evaluate(policy: ignore, method: .get, attempt: 1, error: .rateLimited(retryAfter: 999, context(429))) == .retry(after: 0.5))
    }

    @Test("timeout and connectivity errors retry per the URLError code set")
    func transportErrorsRetry() {
        let policy = noJitter
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 1, error: .timeout) == .retry(after: 0.5))
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 1, error: .noInternet) == .retry(after: 0.5))
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 1, error: .transport(underlying: URLError(.dnsLookupFailed))) == .retry(after: 0.5))
        #expect(RetryDecision.evaluate(policy: policy, method: .get, attempt: 1, error: .transport(underlying: URLError(.badURL))) == .stop)
    }

    @Test(".none policy never retries")
    func nonePolicy() {
        #expect(RetryDecision.evaluate(policy: .none, method: .get, attempt: 1, error: .server(context(503))) == .stop)
    }
}
