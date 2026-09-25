import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

/// A token store that errors (a locked keychain, a full disk) must never be mistaken for an empty one.
@Suite("Token storage failures")
struct TokenStorageFailureTests {

    private struct StorageFailure: Error {}
    private struct RefreshDenied: Error {}
    private struct Thing: Codable, Equatable, Sendable { let v: String }

    private struct SecureEndpoint: Endpoint {
        typealias Response = Thing
        let path = "/me"
        var authentication: AuthRequirement = .required
    }

    private struct FlakyStorage: TokenStorage {
        let inner: InMemoryTokenStorage
        var failReads = false
        var failWrites = false
        var failClears = false

        func data(forKey key: String) async throws -> Data? {
            if failReads { throw StorageFailure() }
            return await inner.data(forKey: key)
        }

        func setData(_ data: Data?, forKey key: String) async throws {
            let shouldFail = data == nil ? failClears : failWrites
            if shouldFail { throw StorageFailure() }
            await inner.setData(data, forKey: key)
        }

        func removeAll() async throws {
            await inner.removeAll()
        }
    }

    private func seeded(expiresIn seconds: TimeInterval? = nil) -> InMemoryTokenStorage {
        InMemoryTokenStorage(
            seed: TokenPair(
                accessToken: "old",
                refreshToken: "r",
                expiresAt: seconds.map { Date(timeIntervalSinceNow: $0) }
            ))
    }

    private let body = Data(#"{"v":"ok"}"#.utf8)

    @Test("an unreadable store fails the request instead of sending it unauthenticated")
    func unreadableStoreWithoutRefresh() async {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tokenStorage = FlakyStorage(inner: seeded(), failReads: true)
        let transport = MockNetworkTransport(default: .json(body))
        let client = NetworkClient(configuration: config, transport: transport)

        await #expect(throws: NetworkError.self) { try await client.request(SecureEndpoint()) }
        #expect(transport.requestCount == 0)
    }

    @Test("with auto-refresh on, an unreadable store fails the request and does not log the user out")
    func unreadableStoreWithRefresh() async {
        let expired = Counter()
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tokenStorage = FlakyStorage(inner: seeded(), failReads: true)
        let transport = MockNetworkTransport(default: .json(body))
        let client = NetworkClient(
            configuration: config, transport: transport,
            refresh: { _ in TokenPair(accessToken: "new") },
            onSessionExpired: { await expired.increment() }
        )

        await #expect(throws: NetworkError.self) { try await client.request(SecureEndpoint()) }
        #expect(transport.requestCount == 0)
        #expect(await expired.value == 0)
    }

    @Test("a refreshed pair that cannot be persisted fails the refresh without signing the user out")
    func refreshedPairNotPersisted() async {
        let expired = Counter()
        let manager = TokenManager(
            storage: FlakyStorage(inner: seeded(), failWrites: true),
            refresh: { _ in TokenPair(accessToken: "new", refreshToken: "r2") },
            onSessionExpired: { await expired.increment() }
        )

        let error = await #expect(throws: NetworkError.self) {
            try await manager.refreshedToken(forRetryOf: RequestID())
        }
        #expect(error?.code == .tokenRefreshFailed)
        #expect(await expired.value == 0)
    }

    @Test("a failed token clear on session expiry is logged and the logout callback still runs")
    func clearFailureIsReported() async {
        let logger = CapturingLogger()
        let expired = Counter()
        let manager = TokenManager(
            storage: FlakyStorage(inner: seeded(), failClears: true),
            refresh: { _ in throw RefreshDenied() },
            onSessionExpired: { await expired.increment() },
            logger: logger
        )

        _ = try? await manager.refreshedToken(forRetryOf: RequestID())

        #expect(await expired.value == 1)
        #expect(logger.entries.contains { $0.level == .error && $0.line.contains("could not clear stored tokens") })
    }

    @Test("a failed proactive refresh propagates instead of sending an unauthenticated request")
    func proactiveRefreshFailurePropagates() async {
        let manager = TokenManager(
            storage: seeded(expiresIn: 5),
            proactiveLeeway: 60,
            refresh: { _ in throw RefreshDenied() }
        )

        let error = await #expect(throws: NetworkError.self) { try await manager.outgoingToken() }
        #expect(error?.code == .tokenRefreshFailed)
    }
}
