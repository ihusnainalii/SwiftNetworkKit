import Foundation
import SwiftNetworkKit

/// A runnable CLI tour of SwiftNetworkKit as it stands after milestones M0–M12.
///
/// ```
/// swift run NetworkKitDemo            # hits the live jsonplaceholder.typicode.com API
/// swift run NetworkKitDemo --offline  # auth/refresh section only (no network)
/// ```
@main
struct NetworkKitDemo {

    static func main() async {
        let offline = CommandLine.arguments.contains("--offline")
        print("═══ SwiftNetworkKit demo (M0–M12) ═══\n")

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
        await uploadDownloadTour()
        await cachingTour()
        await requestManagementTour()
        await oauthTour()
        await offlineQueueTour()
        if !offline { await paginationAndBatchTour() }

        print("\n═══ done ═══")
    }

    // MARK: - SSL pinning (record-only mode, real network)

    private static func sslPinningTour() async {
        print("\n── SSL pinning — .development mode prints the live pins to paste into production ──")

        let logger = CapturingLogger()
        var configuration = NetworkConfiguration(baseURL: "https://jsonplaceholder.typicode.com")
        // recordOnly: never blocks, logs the computed sha256/… for the server's cert chain.
        configuration.sslPinning = .development(
            .publicKeys([], hosts: ["jsonplaceholder.typicode.com"]))
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
                CreatePostEndpoint(
                    draft: DraftPost(title: "Hello", body: "from SwiftNetworkKit", userID: 1))
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
                print("   → isRetryable: \(error.isRetryable) — a 404 is not worth retrying")
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

        let clock = TestClock()  // records backoff waits instead of really sleeping

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
            func process(
                _ context: ResponseContext, for endpoint: AnyEndpoint
            ) async throws
                -> InterceptOutcome
            {
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

        _ = try? await client.request(SecretEndpoint())  // succeeds
        do { _ = try await client.request(SecretEndpoint()) }  // interceptor fails it
        catch {
            print(
                "   ✗ second call rejected by response interceptor: .\(NetworkError.normalize(error).code)")
        }

        let sentVersion =
            transport.recordedRequests.first?.value(forHTTPHeaderField: "X-App-Version") ?? "-"
        print("   → X-App-Version sent by request interceptor: \(sentVersion)")
        print(
            "   → X-Request-ID auto-added: \(transport.recordedRequests.first?.value(forHTTPHeaderField: "X-Request-ID") ?? "-")"
        )

        print("   → captured log lines (Authorization/token redacted):")
        for line in logger.lines { print("       \(line)") }

        let snapshot = await metrics.snapshot()
        print(
            "   → metrics: \(snapshot.requestCount) requests, \(snapshot.successCount) ok, \(snapshot.failureCount) failed, histogram \(snapshot.statusCodeHistogram)"
        )
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

    // MARK: - Multipart upload + download with progress (mock transport)

    private static func uploadDownloadTour() async {
        print("\n── 11. Multipart upload + download with progress (mock transport) ──")

        struct Created: Codable, Sendable { let id: Int }
        struct Upload: Endpoint {
            typealias Response = Created
            let path = "/photos"
            let method = HTTPMethod.post
        }
        struct Fetch: Endpoint {
            typealias Response = Data
            let path = "/photos/1/raw"
        }

        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(Data(#"{"id":101}"#.utf8), status: 201),
            .success(status: 200, headers: [:], body: Data(repeating: 0x2A, count: 8192))
        )
        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"), transport: transport)

        var form = MultipartFormData(boundary: "demo-boundary")
        form.append("a cat photo", name: "caption")
        form.append(
            Data(repeating: 0xFF, count: 4096), name: "photo", fileName: "cat.jpg", mimeType: "image/jpeg"
        )
        print(
            "   → multipart body is \(try! form.encoded().count) bytes, Content-Type: \(form.contentType)"
        )

        let created = try? await client.upload(Upload(), from: .multipart(form)) { event in
            print("     upload \(Int((event.fraction ?? 0) * 100))%")
        }
        print("   → server created photo id \(created?.id ?? -1)")

        let file = try? await client.download(Fetch()) { event in
            print("     download \(event.completed)/\(event.total) bytes")
        }
        if let file, let data = try? Data(contentsOf: file) {
            print("   → downloaded \(data.count) bytes to \(file.lastPathComponent)")
            try? FileManager.default.removeItem(at: file)
        }
    }

    // MARK: - HTTP caching (mock transport)

    private static func cachingTour() async {
        print("\n── 12. HTTP caching — cacheFirst, 304 revalidation, stale-while-revalidate ──")

        struct Doc: Codable, Sendable { let text: String }
        struct GetDoc: Endpoint {
            typealias Response = Doc
            let path = "/doc"
        }

        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(
                Data(#"{"text":"v1"}"#.utf8), headers: ["ETag": "\"1\"", "Cache-Control": "max-age=0"]),
            .status(304, headers: ["ETag": "\"1\""]),
            .json(
                Data(#"{"text":"v2"}"#.utf8), headers: ["ETag": "\"2\"", "Cache-Control": "max-age=60"])
        )

        var configuration = NetworkConfiguration(baseURL: "https://api.example.com")
        configuration.cache = CacheConfiguration(store: MemoryCacheStore(), defaultPolicy: .cacheFirst)
        let client = NetworkClient(configuration: configuration, transport: transport)

        let first = try? await client.request(GetDoc())
        print("   → 1st call: \"\(first?.text ?? "-")\" (from network, stored with ETag)")

        let second = try? await client.request(GetDoc())
        print(
            "   → 2nd call: \"\(second?.text ?? "-")\" (max-age=0 -> revalidated; server said 304, cached body reused)"
        )
        print(
            "     If-None-Match sent: \(transport.recordedRequests.last?.value(forHTTPHeaderField: "If-None-Match") ?? "-")"
        )
        print("   → transport hit \(transport.requestCount)x for 2 logical requests")
    }

    // MARK: - Request management: cancellation, dedup, concurrency limit (mock transport)

    private static func requestManagementTour() async {
        print("\n── 13. Request management — cancel by id, deduplication, concurrency limit ──")

        struct Doc: Codable, Sendable { let n: Int }
        struct GetDoc: Endpoint {
            typealias Response = Doc
            let path = "/doc"
        }

        // Cancellation by id
        let slow = MockNetworkTransport(latency: .milliseconds(500))
        slow.enqueue(.json(Data(#"{"n":1}"#.utf8)))
        let cancelClient = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"), transport: slow)
        let id = RequestID()
        let task = Task { try await cancelClient.request(GetDoc(), id: id) }
        try? await Task.sleep(for: .milliseconds(30))
        await cancelClient.cancel(id)
        if case .failure(let error) = await task.result {
            print("   → cancel(id:) -> .\(NetworkError.normalize(error).code)")
        }

        // Deduplication: 5 concurrent identical GETs, one network call
        let dedupTransport = MockNetworkTransport(latency: .milliseconds(40))
        for _ in 0..<5 { dedupTransport.enqueue(.json(Data(#"{"n":7}"#.utf8))) }
        var dedupConfig = NetworkConfiguration(baseURL: "https://api.example.com")
        dedupConfig.enableDeduplication = true
        let dedupClient = NetworkClient(configuration: dedupConfig, transport: dedupTransport)
        _ = try? await withThrowingTaskGroup(of: Doc.self) { group in
            for _ in 0..<5 { group.addTask { try await dedupClient.request(GetDoc()) } }
            return try await group.reduce(into: [Doc]()) { $0.append($1) }
        }
        print(
            "   → 5 concurrent identical GETs, enableDeduplication -> transport hit \(dedupTransport.requestCount)x"
        )

        // Concurrency limit
        let limited = MockNetworkTransport(
            default: .json(Data(#"{"n":0}"#.utf8)), latency: .milliseconds(20))
        var limitConfig = NetworkConfiguration(baseURL: "https://api.example.com")
        limitConfig.maxConcurrentRequests = 2
        let limitClient = NetworkClient(configuration: limitConfig, transport: limited)
        _ = try? await withThrowingTaskGroup(of: Void.self) { group in
            for _ in 0..<10 { group.addTask { _ = try await limitClient.request(GetDoc()) } }
            try await group.waitForAll()
        }
        print(
            "   → 10 requests through maxConcurrentRequests=2 -> all \(limited.requestCount) completed, never >2 in flight"
        )
    }

    // MARK: - OAuth 2.0 + PKCE (URL building + token exchange via mock transport)

    private static func oauthTour() async {
        print("\n── 14. OAuth 2.0 Authorization Code + PKCE ──")

        let config = OAuthConfiguration(
            authorizationEndpoint: URL(string: "https://auth.example.com/authorize")!,
            tokenEndpoint: URL(string: "https://auth.example.com/token")!,
            clientID: "demo-client",
            redirectURI: "networkkitdemo://callback",
            scopes: ["openid", "profile"]
        )

        let transport = MockNetworkTransport()
        transport.enqueue(
            .json(
                Data(
                    #"""
                    {"access_token":"AT-123","refresh_token":"RT-456","expires_in":3600,"token_type":"Bearer"}
                    """#.utf8)))
        let flow = AuthorizationCodeFlow(configuration: config, transport: transport)

        let state = AuthorizationCodeFlow.makeState()
        let pkce = PKCE()
        let authURL = flow.authorizationURL(state: state, pkce: pkce)
        print("   → authorization URL (open this in ASWebAuthenticationSession):")
        print("       \(authURL.absoluteString)")

        // The provider redirects back with ?code=...&state=...
        let redirect = URL(string: "networkkitdemo://callback?code=AUTH_CODE&state=\(state)")!
        do {
            let code = try flow.authorizationCode(fromRedirect: redirect, expectedState: state)
            let tokens = try await flow.exchange(code: code, pkce: pkce)
            print(
                "   → exchanged code for access token \"\(tokens.accessToken)\", expires \(tokens.expiryDate.map { "\(Int($0.timeIntervalSinceNow))s" } ?? "n/a")"
            )
            print(
                "   → wire flow.tokenManagerRefreshHandler() into NetworkClient(refresh:) for automatic refresh"
            )
        } catch {
            print("   → \(error)")
        }
    }

    // MARK: - Offline request queue (mock transport + mock monitor)

    private static func offlineQueueTour() async {
        print("\n── 15. Offline request queue — persist while offline, replay on reconnect ──")

        struct Ack: Codable, Sendable { let ok: Bool }
        struct SubmitOrder: Endpoint {
            typealias Response = Ack
            let path = "/orders"
            let method = HTTPMethod.post
            var offlineBehavior: OfflineBehavior { .queue(expiresAfter: 3600) }
        }

        let transport = MockNetworkTransport()
        transport.enqueue(.failure(.noInternet), .json(Data(#"{"ok":true}"#.utf8), status: 201))

        let monitor = MockNetworkMonitor(initial: .unsatisfied)
        let store = InMemoryOfflineStore()

        var configuration = NetworkConfiguration(baseURL: "https://api.example.com")
        configuration.retry = .none
        configuration.offlineStore = store
        configuration.networkMonitor = monitor
        let client = NetworkClient(configuration: configuration, transport: transport)

        do {
            _ = try await client.request(SubmitOrder())
        } catch let error as NetworkError {
            if case .offlineQueued(let id) = error {
                print("   → offline: SubmitOrder persisted as \(id), caller got .offlineQueued")
            }
        } catch {
            print("   → \(error)")
        }
        print("   → \(await store.count) request(s) waiting in the queue")

        let events = await client.offlineReplayEvents()
        await monitor.send(.satisfied(.wifi))  // ...connectivity returns

        for await event in events {
            if case .replayed(let id, let status) = event {
                print("   → reconnected: replayed \(id) -> HTTP \(status)")
            }
            break
        }
        print("   → \(await store.count) request(s) left in the queue")
    }

    // MARK: - Pagination + batch (live jsonplaceholder API)

    private static func paginationAndBatchTour() async {
        print("\n── 16. Pagination (AsyncSequence) + parallel batch ──")

        struct User: Codable, Sendable {
            let id: Int
            let name: String
        }
        struct UsersPage: PaginatedEndpoint {
            typealias Response = [User]
            var page = 1
            var path: String { "/users" }
            var queryParameters: QueryParameters? { ["_page": .int(page), "_limit": .int(4)] }
            func items(from response: [User]) -> [User] { response }
            func nextPage(after response: [User]) -> UsersPage? {
                response.isEmpty ? nil : UsersPage(page: page + 1)
            }
        }
        struct Post: Codable, Sendable { let id: Int }
        struct PostsByUser: Endpoint {
            typealias Response = [Post]
            let userID: Int
            var path: String { "/posts" }
            var queryParameters: QueryParameters? { ["userId": .int(userID)] }
        }

        let client = NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://jsonplaceholder.typicode.com"))

        do {
            var pageIndex = 0
            for try await users in client.paginate(UsersPage()) {
                pageIndex += 1
                print("   → page \(pageIndex): \(users.map(\.name).joined(separator: ", "))")
            }

            let all = try await client.collectAll(UsersPage())
            print("   → collectAll: \(all.count) users total")

            let (p1, p2, p3) = try await client.zip(
                PostsByUser(userID: 1), PostsByUser(userID: 2), PostsByUser(userID: 3))
            print(
                "   → zip: users 1/2/3 have \(p1.count)/\(p2.count)/\(p3.count) posts (fetched in parallel)"
            )

            let results = await client.batch((1...5).map { PostsByUser(userID: $0) })
            let counts = results.map { (try? $0.get())?.count ?? -1 }
            print("   → batch of 5: post counts \(counts)")
        } catch {
            print("   → \(error)")
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
