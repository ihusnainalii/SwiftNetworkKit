import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("TokenManager")
struct TokenManagerTests {

    @Test("20 concurrent 401s trigger exactly one refresh")
    func singleFlight() async throws {
        let refreshCount = Counter()
        let manager = TokenManager(
            storage: InMemoryTokenStorage(seed: TokenPair(accessToken: "old", refreshToken: "r")),
            refresh: { _ in
                await refreshCount.increment()
                try await Task.sleep(for: .milliseconds(30))
                return TokenPair(accessToken: "new", refreshToken: "r2")
            }
        )

        try await withThrowingTaskGroup(of: String.self) { group in
            for _ in 0..<20 {
                group.addTask { try await manager.refreshedToken(forRetryOf: RequestID()) }
            }
            for try await token in group { #expect(token == "new") }
        }

        #expect(await refreshCount.value == 1)
    }

    @Test("second 401 for the same request throws .sessionExpired and fires the callback once")
    func loopGuard() async throws {
        let expiredCount = Counter()
        let manager = TokenManager(
            storage: InMemoryTokenStorage(seed: TokenPair(accessToken: "old", refreshToken: "r")),
            refresh: { _ in TokenPair(accessToken: "new") },
            onSessionExpired: { await expiredCount.increment() }
        )

        let id = RequestID()
        #expect(try await manager.refreshedToken(forRetryOf: id) == "new")

        let error = await #expect(throws: NetworkError.self) {
            try await manager.refreshedToken(forRetryOf: id)
        }
        #expect(error?.code == .sessionExpired)
        #expect(await expiredCount.value == 1)
    }

    @Test("refresh failure clears tokens, fires onSessionExpired once, surfaces .tokenRefreshFailed")
    func refreshFailure() async throws {
        struct RefreshDenied: Error {}
        let expiredCount = Counter()
        let storage = InMemoryTokenStorage(seed: TokenPair(accessToken: "old", refreshToken: "r"))
        let manager = TokenManager(
            storage: storage,
            refresh: { _ in throw RefreshDenied() },
            onSessionExpired: { await expiredCount.increment() }
        )

        let error = await #expect(throws: NetworkError.self) {
            try await manager.refreshedToken(forRetryOf: RequestID())
        }
        #expect(error?.code == .tokenRefreshFailed)
        #expect(await expiredCount.value == 1)
        #expect(try await storage.accessToken() == nil)
    }

    @Test("tokenForOutgoingRequest refreshes a token within the proactive leeway")
    func proactiveRefresh() async throws {
        let refreshCount = Counter()
        let manager = TokenManager(
            storage: InMemoryTokenStorage(seed: TokenPair(
                accessToken: "old",
                refreshToken: "r",
                expiresAt: Date(timeIntervalSinceNow: 10)
            )),
            proactiveLeeway: 60,
            refresh: { _ in
                await refreshCount.increment()
                return TokenPair(accessToken: "fresh", refreshToken: "r2")
            }
        )

        #expect(await manager.tokenForOutgoingRequest() == "fresh")
        #expect(await refreshCount.value == 1)
    }

    @Test("tokenForOutgoingRequest returns a still-valid token without refreshing")
    func noPrematureRefresh() async {
        let refreshCount = Counter()
        let manager = TokenManager(
            storage: InMemoryTokenStorage(seed: TokenPair(
                accessToken: "valid",
                refreshToken: "r",
                expiresAt: Date(timeIntervalSinceNow: 3_600)
            )),
            refresh: { _ in await refreshCount.increment(); return TokenPair(accessToken: "x") }
        )

        #expect(await manager.tokenForOutgoingRequest() == "valid")
        #expect(await refreshCount.value == 0)
    }
}
