import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("TokenStorage")
struct TokenStorageTests {

    @Test("InMemoryTokenStorage round-trips a token pair")
    func inMemoryRoundTrip() async throws {
        let storage = InMemoryTokenStorage()
        #expect(try await storage.currentTokenPair() == nil)

        let pair = TokenPair(accessToken: "a", refreshToken: "r", expiresAt: Date(timeIntervalSince1970: 1_000))
        try await storage.store(pair)
        #expect(try await storage.accessToken() == "a")
        #expect(try await storage.refreshToken() == "r")
        #expect(try await storage.currentTokenPair() == pair)

        try await storage.clearTokenPair()
        #expect(try await storage.accessToken() == nil)
    }

    @Test("InMemoryTokenStorage can be seeded")
    func seeded() async throws {
        let storage = InMemoryTokenStorage(seed: TokenPair(accessToken: "seed"))
        #expect(try await storage.accessToken() == "seed")
    }

    @Test("generic key/value slots")
    func genericSlots() async {
        let storage = InMemoryTokenStorage()
        await storage.setData(Data("v".utf8), forKey: "custom")
        #expect(await storage.data(forKey: "custom") == Data("v".utf8))
        await storage.removeAll()
        #expect(await storage.data(forKey: "custom") == nil)
    }

    @Test("TokenPair.isExpired honors leeway")
    func expiry() {
        #expect(TokenPair(accessToken: "a").isExpired() == false)
        #expect(TokenPair(accessToken: "a", expiresAt: Date(timeIntervalSinceNow: -1)).isExpired())
        #expect(TokenPair(accessToken: "a", expiresAt: Date(timeIntervalSinceNow: 30)).isExpired(leeway: 60))
        #expect(TokenPair(accessToken: "a", expiresAt: Date(timeIntervalSinceNow: 120)).isExpired(leeway: 60) == false)
    }

    #if canImport(Security)
    @Test("KeychainTokenStorage round-trips when the keychain is available")
    func keychainRoundTrip() async throws {
        try #require(KeychainTokenStorage.isAvailable, "keychain unavailable in this environment")
        let storage = KeychainTokenStorage(service: "com.swiftnetworkkit.tests.\(UUID().uuidString)")
        defer { Task { try? await storage.removeAll() } }

        #expect(try await storage.accessToken() == nil)
        try await storage.store(TokenPair(accessToken: "k", refreshToken: "kr"))
        #expect(try await storage.accessToken() == "k")
        try await storage.store(TokenPair(accessToken: "k2"))
        #expect(try await storage.accessToken() == "k2")
        try await storage.removeAll()
        #expect(try await storage.accessToken() == nil)
    }
    #endif
}
