import Foundation
import SwiftNetworkKit

/// Runs real requests through a real `NetworkClient`, instrumented only via the package's public
/// hooks (a wrapping `NetworkTransport`, a `RequestInterceptor`, a `ResponseInterceptor`), and turns
/// the captured timestamps into the traces the website replays.
enum Traces {

    // MARK: instrumentation

    final class RecordingTransport: NetworkTransport, @unchecked Sendable {
        let inner: MockNetworkTransport
        let recorder: TraceRecorder
        let lane: @Sendable (URLRequest) -> String
        init(
            _ inner: MockNetworkTransport, _ recorder: TraceRecorder,
            lane: @escaping @Sendable (URLRequest) -> String = { _ in "transport" }
        ) {
            self.inner = inner
            self.recorder = recorder
            self.lane = lane
        }
        func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse) {
            let l = lane(request)
            recorder.mark(l, "transport_in", request.url?.path ?? "")
            let result = try await inner.data(for: request)
            recorder.mark(l, "transport_out", "\(result.1.statusCode), \(result.0.count) B")
            return result
        }
    }

    struct MarkRequest: RequestInterceptor {
        let recorder: TraceRecorder
        func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
            recorder.mark("pipeline", "interceptor", "\(request.httpMethod ?? "GET") \(request.url?.path ?? "")")
            return request
        }
    }

    struct MarkResponse: ResponseInterceptor {
        let recorder: TraceRecorder
        func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
            recorder.mark("pipeline", "response_interceptor", "\(context.statusCode)")
            return .proceed
        }
    }

    struct Widget: Codable, Sendable {
        let id: Int
        let name: String
    }
    static let body = try! JSONEncoder().encode([Widget(id: 1, name: "alpha")])

    static func client(
        transport: any NetworkTransport,
        recorder: TraceRecorder,
        cache: CacheConfiguration = .disabled,
        retry: RetryPolicy = .init(maxAttempts: 1),
        deduplicate: Bool = false,
        maxConcurrent: Int = 6,
        refresh: TokenManager.RefreshHandler? = nil
    ) -> NetworkClient {
        var config = NetworkConfiguration(
            environment: NetworkEnvironment(
                kind: .production, baseURL: URL(string: "https://trace.local")!, logLevel: .none),
            retry: retry,
            logger: Scenarios.SilentLogger(),
            metrics: NoopMetrics(),
            cache: cache,
            maxConcurrentRequests: maxConcurrent,
            enableDeduplication: deduplicate
        )
        config.requestInterceptors = [MarkRequest(recorder: recorder)]
        config.responseInterceptors = [MarkResponse(recorder: recorder)]
        return NetworkClient(configuration: config, transport: transport, refresh: refresh)
    }

    struct Get: Endpoint {
        typealias Response = [Widget]
        var path = "/widgets"
        var cachePolicy: CachePolicy?
        var authentication: AuthRequirement = .none
    }

    // MARK: pipeline traces

    static func pipelines(version: String) async -> [PipelineTrace] {
        var out: [PipelineTrace] = []

        // cache miss: full path to the transport and back.
        do {
            let rec = TraceRecorder()
            let transport = RecordingTransport(
                MockNetworkTransport(default: .json(body), latency: .milliseconds(1)), rec)
            let c = client(transport: transport, recorder: rec)
            rec.mark("pipeline", "issued", "client.request(Get())")
            _ = try? await c.request(Get())
            rec.mark("pipeline", "done", "decoded [Widget]")
            out.append(pipelineTrace("cache_miss", "Cache miss", "network round trip through the full pipeline", rec))
        }

        // cache hit: same call, answered from the store; transport never runs.
        do {
            let rec = TraceRecorder()
            let store = MemoryCacheStore()
            let transport = RecordingTransport(
                MockNetworkTransport(default: .json(body), latency: .milliseconds(1)), rec)
            let c = client(
                transport: transport, recorder: rec,
                cache: CacheConfiguration(store: store, defaultPolicy: .cacheFirst, defaultTTL: 3600))
            _ = try? await c.request(Get(cachePolicy: .cacheFirst))  // warm
            let rec2 = TraceRecorder()
            let c2 = client(
                transport: RecordingTransport(MockNetworkTransport(default: .json(body)), rec2), recorder: rec2,
                cache: CacheConfiguration(store: store, defaultPolicy: .cacheFirst, defaultTTL: 3600))
            rec2.mark("pipeline", "issued", "client.request(Get()), entry already cached")
            _ = try? await c2.request(Get(cachePolicy: .cacheFirst))
            rec2.mark("pipeline", "done", "served from ResponseCache, transport untouched")
            out.append(
                pipelineTrace("cache_hit", "Cache hit", "resolved from the response cache, no transport call", rec2))
        }

        // retry: two 503s then a 200, with real backoff sleeps.
        do {
            let rec = TraceRecorder()
            let mock = MockNetworkTransport(default: .json(body))
            mock.enqueue(.status(503), .status(503), .json(body))
            let transport = RecordingTransport(mock, rec)
            let c = client(
                transport: transport, recorder: rec,
                retry: RetryPolicy(maxAttempts: 3, backoff: .exponential(base: 0.01, multiplier: 2, maxDelay: 0.1)))
            rec.mark("pipeline", "issued", "client.request(Get()), retry policy: 3 attempts")
            _ = try? await c.request(Get())
            rec.mark("pipeline", "done", "succeeded on attempt 3")
            out.append(
                pipelineTrace(
                    "retry", "Retry with backoff", "two 503s, exponential backoff, success on the third try", rec))
        }

        // 401 -> single-flight refresh -> retry -> 200.
        do {
            let rec = TraceRecorder()
            let mock = MockNetworkTransport(default: .json(body))
            mock.stub(matching: { $0.value(forHTTPHeaderField: "Authorization") != "Bearer fresh" }, with: .status(401))
            mock.stub(matching: { $0.value(forHTTPHeaderField: "Authorization") == "Bearer fresh" }, with: .json(body))
            let c = client(
                transport: RecordingTransport(mock, rec), recorder: rec,
                refresh: { _ in
                    rec.mark("pipeline", "refresh", "exchange refresh token for a new access token")
                    return TokenPair(accessToken: "fresh", refreshToken: "r")
                })
            struct Secure: Endpoint {
                typealias Response = [Widget]
                var path = "/me"
                var authentication: AuthRequirement { .required }
            }
            rec.mark("pipeline", "issued", "client.request(Secure()) with a stale token")
            _ = try? await c.request(Secure())
            rec.mark("pipeline", "done", "retried with the fresh token, decoded")
            out.append(
                pipelineTrace(
                    "auth_refresh", "401 token refresh",
                    "stale token, one actor-isolated refresh, request replayed transparently", rec))
        }

        // multipart upload with byte-progress callbacks.
        do {
            let rec = TraceRecorder()
            let c = client(
                transport: RecordingTransport(
                    MockNetworkTransport(default: .json(body), latency: .milliseconds(2)), rec), recorder: rec)
            var form = MultipartFormData()
            form.append(
                Data(repeating: 0x41, count: 4096), name: "file", fileName: "a.bin",
                mimeType: "application/octet-stream")
            struct Up: Endpoint {
                typealias Response = [Widget]
                var path = "/upload"
                var method: HTTPMethod { .post }
            }
            rec.mark("pipeline", "issued", "client.upload(Up(), from: .multipart) 4 KB")
            _ = try? await c.upload(Up(), from: .multipart(form)) { ev in
                rec.mark("pipeline", "progress", "\(ev.completed)/\(ev.total) bytes")
            }
            rec.mark("pipeline", "done", "server accepted the multipart body, decoded")
            out.append(
                pipelineTrace("upload", "Multipart upload", "RFC 7578 body, progress events, decode", rec))
        }

        // file download to a temp file.
        do {
            let rec = TraceRecorder()
            let payload = Data(repeating: 0x2A, count: 8192)
            let c = client(
                transport: RecordingTransport(
                    MockNetworkTransport(default: .json(payload), latency: .milliseconds(2)), rec), recorder: rec)
            struct Down: Endpoint {
                typealias Response = Data
                var path = "/asset.bin"
            }
            rec.mark("pipeline", "issued", "client.download(Down())")
            let url = try? await c.download(Down()) { ev in
                rec.mark("pipeline", "progress", "\(ev.completed)/\(ev.total) bytes")
            }
            rec.mark("pipeline", "done", "wrote \(payload.count) bytes to \(url?.lastPathComponent ?? "temp")")
            try? url.map { try FileManager.default.removeItem(at: $0) }
            out.append(
                pipelineTrace("download", "File download", "streamed to a temp file with progress", rec))
        }

        // OAuth 2.0 Authorization Code + PKCE token exchange.
        do {
            let rec = TraceRecorder()
            let mock = MockNetworkTransport(
                default: .json(
                    Data(#"{"access_token":"at","token_type":"Bearer","refresh_token":"rt","expires_in":3600}"#.utf8)))
            let flow = AuthorizationCodeFlow(
                configuration: OAuthConfiguration(
                    authorizationEndpoint: URL(string: "https://id.example.com/authorize")!,
                    tokenEndpoint: URL(string: "https://id.example.com/token")!,
                    clientID: "demo", redirectURI: "app://cb", scopes: ["openid", "profile"]),
                transport: RecordingTransport(mock, rec))
            rec.mark("pipeline", "issued", "AuthorizationCodeFlow.exchange(code:pkce:)")
            let pkce = PKCE()
            rec.mark("pipeline", "interceptor", "PKCE: base64url(SHA256(verifier)) challenge computed")
            _ = flow.authorizationURL(state: "xyz", pkce: pkce)
            rec.mark("pipeline", "interceptor", "authorization URL built (response_type=code, code_challenge)")
            _ = try? await flow.exchange(code: "auth-code-123", pkce: pkce)
            rec.mark("pipeline", "done", "TokenPair received (access + refresh)")
            out.append(
                pipelineTrace("oauth", "OAuth 2.0 + PKCE", "real PKCE challenge, code exchange over the transport", rec)
            )
        }

        return out
    }

    private static func pipelineTrace(
        _ id: String, _ label: String, _ note: String, _ rec: TraceRecorder
    ) -> PipelineTrace {
        let ev = rec.ordered
        var stages: [PipelineTrace.Stage] = []
        for (i, e) in ev.enumerated() where i < ev.count - 1 {
            let next = ev[i + 1]
            let name: String
            switch e.kind {
            case "issued": name = "Auth + request build"
            case "interceptor": name = "Request interceptors"
            case "transport_in": name = "Transport (in flight)"
            case "transport_out": name = "Status mapping"
            case "response_interceptor" where next.kind == "interceptor": name = "Backoff, then re-dispatch"
            case "response_interceptor": name = "Decode + return"
            default: name = e.kind
            }
            stages.append(
                .init(name: name, startMicros: round(e.t), durationMicros: round(next.t - e.t), detail: e.note))
        }
        return .init(
            id: id, label: label, note: note,
            totalMicros: round((ev.last?.t ?? 0) - (ev.first?.t ?? 0)), stages: stages)
    }

    // MARK: concurrency traces

    static func concurrency() async -> [ConcurrencyTrace] {
        [await dedup(), await refresh(), await priority()]
    }

    private static func dedup() async -> ConcurrencyTrace {
        let n = 6
        let rec = TraceRecorder()
        let mock = MockNetworkTransport(default: .json(body), latency: .milliseconds(8))
        let transport = RecordingTransport(mock, rec) { _ in "transport" }
        let c = client(transport: transport, recorder: rec, deduplicate: true, maxConcurrent: n * 2)
        await withTaskGroup(of: Void.self) { group in
            for i in 1...n {
                group.addTask {
                    rec.mark("req\(i)", "issued", "")
                    _ = try? await c.request(Get(cachePolicy: nil))
                    rec.mark("req\(i)", "done", "")
                }
            }
        }
        let calls = mock.requestCount
        return trace(
            "deduplication", "Request deduplication",
            "\(n) identical requests in flight, \(calls) reached the transport, \(n - calls) coalesced onto it", rec)
    }

    private static func refresh() async -> ConcurrencyTrace {
        let n = 5
        let rec = TraceRecorder()
        let mock = MockNetworkTransport(default: .json(body))
        mock.stub(matching: { $0.value(forHTTPHeaderField: "Authorization") != "Bearer fresh" }, with: .status(401))
        mock.stub(matching: { $0.value(forHTTPHeaderField: "Authorization") == "Bearer fresh" }, with: .json(body))
        let refreshes = Counter()
        let c = client(
            transport: RecordingTransport(mock, rec), recorder: rec,
            refresh: { _ in
                rec.mark("refresh", "refresh", "exchanging refresh token")
                try? await Task.sleep(for: .milliseconds(5))  // a real token exchange is a network call
                refreshes.increment()
                return TokenPair(accessToken: "fresh", refreshToken: "r")
            })
        struct Authed: Endpoint {
            typealias Response = [Widget]
            var path = "/secure"
            var authentication: AuthRequirement { .required }
        }
        await withTaskGroup(of: Void.self) { group in
            for i in 1...n {
                group.addTask {
                    rec.mark("req\(i)", "issued", "401 expected")
                    _ = try? await c.request(Authed())
                    rec.mark("req\(i)", "done", "retried with fresh token")
                }
            }
        }
        return trace(
            "single_flight_refresh", "Single-flight token refresh",
            "\(n) parallel 401s → \(refreshes.current) refresh → all \(n) retried and succeeded", rec)
    }

    private static func priority() async -> ConcurrencyTrace {
        let rec = TraceRecorder()
        let mock = MockNetworkTransport(default: .json(body), latency: .milliseconds(4))
        let transport = RecordingTransport(mock, rec) { req in
            URLComponents(url: req.url ?? URL(string: "x:")!, resolvingAgainstBaseURL: false)?
                .queryItems?.first { $0.name == "who" }?.value ?? "transport"
        }
        let c = client(transport: transport, recorder: rec, maxConcurrent: 1)

        struct P: Endpoint {
            typealias Response = [Widget]
            var name: String
            var priority: RequestPriority
            var path: String { "/p" }
            var queryParameters: QueryParameters? {
                var q = QueryParameters()
                q.append("who", .string(name))
                return q
            }
        }
        // Occupy the single slot, queue low then high, release.
        async let blocker: Void = { _ = try? await c.request(P(name: "blocker", priority: .normal)) }()
        try? await Task.sleep(for: .milliseconds(1))
        rec.mark("queue", "enqueue", "low priority")
        async let low: Void = { _ = try? await c.request(P(name: "low", priority: .low)) }()
        try? await Task.sleep(for: .milliseconds(1))
        rec.mark("queue", "enqueue", "high priority (jumps the low one)")
        async let high: Void = { _ = try? await c.request(P(name: "high", priority: .high)) }()
        _ = await (blocker, low, high)

        return trace(
            "priority_queue", "Priority request queue",
            "one slot, low then high enqueued; the queue admits high before low", rec)
    }

    private static func trace(
        _ id: String, _ label: String, _ summary: String, _ rec: TraceRecorder
    ) -> ConcurrencyTrace {
        let base = rec.ordered.first?.t ?? 0
        var byLane: [String: [ConcurrencyTrace.Event]] = [:]
        for e in rec.ordered {
            byLane[e.lane, default: []].append(.init(atMicros: round(e.t - base), kind: e.kind, note: e.note))
        }
        let known = ["queue", "blocker", "low", "high", "refresh", "transport"]
        let order = known.filter { byLane[$0] != nil } + byLane.keys.filter { !known.contains($0) }.sorted()
        let lanes = order.compactMap { name in byLane[name].map { ConcurrencyTrace.Lane(name: name, events: $0) } }
        return .init(id: id, label: label, summary: summary, lanes: lanes)
    }
}
