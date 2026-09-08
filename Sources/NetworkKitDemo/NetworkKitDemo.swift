import Foundation
import SwiftNetworkKit

/// A runnable CLI tour of SwiftNetworkKit as it stands after milestones M0–M2.
///
/// ```
/// swift run NetworkKitDemo            # hits the live jsonplaceholder.typicode.com API
/// swift run NetworkKitDemo --offline  # auth/refresh section only (no network)
/// ```
@main
struct NetworkKitDemo {

    static func main() async {
        let offline = CommandLine.arguments.contains("--offline")
        print("═══ SwiftNetworkKit demo (M0–M2) ═══\n")

        if offline {
            print("• Skipping live API sections (--offline)\n")
        } else {
            await liveAPITour()
        }
        await authAndRefreshTour()

        print("\n═══ done ═══")
    }

    // MARK: - Live API (real network)

    private static func liveAPITour() async {
        let client = NetworkClient(
            configuration: NetworkConfiguration(
                baseURL: "https://jsonplaceholder.typicode.com",
                headers: ["Accept": "application/json"]
            )
        )

        await section("1. Typed GET — one model") {
            let user = try await client.request(GetUserEndpoint(id: 1))
            print("   → \(user.name) <\(user.email)> (@\(user.username))")
        }

        await section("2. Typed GET — collection + query parameter") {
            let posts = try await client.request(ListPostsEndpoint(authorUserID: 1))
            print("   → \(posts.count) posts by user 1; first title: \"\(posts.first?.title ?? "-")\"")
        }

        await section("3. POST — JSON body, decoded response") {
            let created = try await client.request(
                CreatePostEndpoint(draft: DraftPost(title: "Hello", body: "from SwiftNetworkKit", userID: 1))
            )
            print("   → created post id \(created.id): \"\(created.title)\"")
        }

        await section("4. Raw helpers — string(for:)") {
            let raw = try await client.string(for: GetUserEndpoint(id: 2))
            print("   → \(raw.prefix(60))…")
        }

        await section("5. Error handling — 404 → typed NetworkError") {
            do {
                _ = try await client.request(MissingUserEndpoint())
                print("   → unexpectedly succeeded")
            } catch let error as NetworkError {
                print("   → caught .\(error.code) (status \(error.statusCode.map(String.init) ?? "-"))")
            }
        }

        await section("6. Completion-handler API") {
            let name: String? = await withCheckedContinuation { continuation in
                client.request(GetUserEndpoint(id: 3)) { result in
                    continuation.resume(returning: try? result.get().name)
                }
            }
            print("   → user 3 is \(name ?? "unknown")")
        }
    }

    // MARK: - Auth + automatic refresh (deterministic, via MockNetworkTransport)

    private static func authAndRefreshTour() async {
        print("\n── 7. Bearer auth + automatic 401 refresh (mock transport) ──")

        let transport = MockNetworkTransport()
        transport.enqueue(
            .success(status: 401, headers: [:], body: Data(#"{"message":"token expired"}"#.utf8)),
            .json(Data(#"{"value":"42"}"#.utf8))
        )

        let refreshCount = DemoCounter()

        let client = NetworkClient(
            configuration: NetworkConfiguration(
                baseURL: "https://api.example.com",
                tokenStorage: InMemoryTokenStorage(seed: TokenPair(accessToken: "stale-token"))
            ),
            transport: transport,
            refresh: { _ in
                await refreshCount.bump()
                print("   ↻ refresh handler called — exchanging refresh token for a new access token")
                return TokenPair(accessToken: "fresh-token")
            },
            onSessionExpired: { print("   ⚠︎ session expired — app would log the user out here") }
        )

        do {
            let secret = try await client.request(SecretEndpoint())
            let sentTokens = transport.recordedRequests.compactMap {
                $0.value(forHTTPHeaderField: "Authorization")
            }
            print("   → got secret \"\(secret.value)\" after \(await refreshCount.count) refresh")
            print("   → Authorization headers seen by the server: \(sentTokens)")
        } catch {
            print("   → failed: \(error)")
        }
    }

    // MARK: - Helpers

    private static func section(_ title: String, _ body: () async throws -> Void) async {
        print("── \(title) ──")
        do {
            try await body()
        } catch let error as NetworkError {
            print("   ✗ NetworkError.\(error.code): \(error.localizedDescription)")
        } catch {
            print("   ✗ \(error)")
        }
        print("")
    }
}
