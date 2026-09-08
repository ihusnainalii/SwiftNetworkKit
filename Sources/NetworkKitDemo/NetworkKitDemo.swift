import Foundation
import SwiftNetworkKit

/// A runnable CLI tour of SwiftNetworkKit as it stands after milestones M0–M6.
///
/// ```
/// swift run NetworkKitDemo            # hits the live jsonplaceholder.typicode.com API
/// swift run NetworkKitDemo --offline  # auth/refresh section only (no network)
/// ```
@main
struct NetworkKitDemo {

    static func main() async {
        let offline = CommandLine.arguments.contains("--offline")
        print("═══ SwiftNetworkKit demo (M0–M6) ═══\n")

        if offline {
            print("• Skipping live API sections (--offline)\n")
        } else {
            await liveAPITour()
            await sslPinningTour()
        }
        await authAndRefreshTour()
        await retryTour()
        await interceptorsAndMetricsTour()
        await reachabilityTour()

        print("\n═══ done ═══")
    }

    // MARK: - SSL pinning (record-only mode, real network)

    private static func sslPinningTour() async {
        print("\n── SSL pinning — .development mode prints the live pins to paste into production ──")

        let logger = CapturingLogger()
        var configuration = NetworkConfiguration(baseURL: "https://jsonplaceholder.typicode.com")
        // recordOnly: never blocks, logs the computed sha256/… for the server's cert chain.
        configuration.sslPinning = .development(.publicKeys([], hosts: ["jsonplaceholder.typicode.com"]))
        configuration.environment.logLevel = .error
        configuration.logger = logger

        let client = NetworkClient(configuration: configuration)
        do {
            _ = try await client.request(GetUserEndpoint(id: 1))
            let pins = logger.lines.filter { $0.contains("recordOnly") }
            print("   → request succeeded (recordOnly never blocks). Discovered pins:")
            for line in pins { print("       \(line)") }
            print("   → swap in `.publicKeys([...])` with one of these for production enforcement")
        } catch {
            print("   → \(error)")
        }
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

    // MARK: - Retry + backoff (deterministic, via MockNetworkTransport + TestClock)

    private static func retryTour() async {
        print("\n── 8. Automatic retry with exponential backoff (mock transport) ──")

        let transport = MockNetworkTransport()
        transport.enqueue(.status(503), .status(503), .json(Data(#"{"value":"42"}"#.utf8)))

        let clock = TestClock() // records backoff waits instead of really sleeping

        var configuration = NetworkConfiguration(baseURL: "https://api.example.com")
        configuration.retry = RetryPolicy(maxAttempts: 3, jitter: .none)
        configuration.clock = clock
        let client = NetworkClient(configuration: configuration, transport: transport)

        do {
            let secret = try await client.request(SecretEndpoint())
            print("   → got \"\(secret.value)\" after \(transport.requestCount) attempts")
            print("   → backoff waits between attempts: \(clock.recordedSleeps)s (0.5, then 1.0)")
        } catch {
            print("   → failed: \(error)")
        }

        print("   note: POST/PATCH are never retried unless an endpoint opts in via retryPolicy")
    }

    // MARK: - Interceptors + redacting logger + metrics (mock transport)

    private static func interceptorsAndMetricsTour() async {
        print("\n── 9. Interceptors, redacting logger, metrics (mock transport) ──")

        struct AppVersionInterceptor: RequestInterceptor {
            func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
                var request = request
                request.setValue("9.9.9", forHTTPHeaderField: "X-App-Version")
                return request
            }
        }
        struct FlagEnvelope: ResponseInterceptor {
            func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
                guard let data = context.data,
                      String(data: data, encoding: .utf8)?.contains("NEEDS_2FA") == true
                else { return .proceed }
                return .fail(.forbidden(context))
            }
        }

        struct Secret: Codable, Sendable { let value: String }
        struct SecretEndpoint: Endpoint {
            typealias Response = Secret
            let path = "/secret"
        }

        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"{"value":"42"}"#.utf8)),
            .json(Data(#"{"code":"NEEDS_2FA"}"#.utf8))
        )

        let logger = CapturingLogger()
        let metrics = InMemoryMetrics()

        var environment = NetworkEnvironment(
            kind: .development,
            baseURL: URL(string: "https://api.example.com")!
        )
        environment.logLevel = .verbose

        var configuration = NetworkConfiguration(environment: environment)
        configuration.retry = .none
        configuration.logger = logger
        configuration.metrics = metrics
        configuration.requestInterceptors = [AppVersionInterceptor()]
        configuration.responseInterceptors = [FlagEnvelope()]

        let client = NetworkClient(configuration: configuration, transport: transport)

        _ = try? await client.request(SecretEndpoint())              // succeeds
        do { _ = try await client.request(SecretEndpoint()) }        // interceptor fails it
        catch { print("   ✗ second call rejected by response interceptor: .\(NetworkError.normalize(error).code)") }

        let sentVersion = transport.recordedRequests.first?.value(forHTTPHeaderField: "X-App-Version") ?? "-"
        print("   → X-App-Version sent by request interceptor: \(sentVersion)")
        print("   → X-Request-ID auto-added: \(transport.recordedRequests.first?.value(forHTTPHeaderField: "X-Request-ID") ?? "-")")

        print("   → captured log lines (Authorization/token redacted):")
        for line in logger.lines { print("       \(line)") }

        let snapshot = await metrics.snapshot()
        print("   → metrics: \(snapshot.requestCount) requests, \(snapshot.successCount) ok, \(snapshot.failureCount) failed, histogram \(snapshot.statusCodeHistogram)")
    }

    // MARK: - Reachability (mock monitor)

    private static func reachabilityTour() async {
        print("\n── 10. Reachability — NetworkMonitor stream + connectionRestored() ──")

        let monitor = MockNetworkMonitor(initial: .satisfied(.wifi))

        let observed = Task { () -> [String] in
            var lines: [String] = []
            for await status in await monitor.statusUpdates() {
                lines.append(String(describing: status))
                if lines.count == 4 { break }
            }
            return lines
        }

        let restores = Task { () -> Int in
            var count = 0
            for await _ in await monitor.connectionRestored() {
                count += 1
                if count == 1 { break }
            }
            return count
        }

        try? await Task.sleep(for: .milliseconds(20))
        await monitor.send([.unsatisfied, .satisfied(.cellular), .unsatisfied])

        print("   → observed: \(await observed.value)")
        print("   → connectionRestored() fired \(await restores.value)x (unsatisfied → satisfied)")

        let live = await PathNetworkMonitor().currentStatus
        print("   → PathNetworkMonitor seeds as \(live) before NWPathMonitor's first callback")
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
