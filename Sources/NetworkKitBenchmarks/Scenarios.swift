import Foundation
import SwiftNetworkKit

/// Every scenario exercises the real SwiftNetworkKit code paths. The network itself is replaced by
/// the package's own ``MockNetworkTransport`` (zero latency unless a scenario needs it), so the
/// numbers are the library's own overhead, not the internet's.
enum Scenarios {

    // MARK: fixtures

    struct Widget: Codable, Sendable {
        let id: Int
        let name: String
        let tags: [String]
        let active: Bool
    }

    struct SilentLogger: NetworkLogger {
        func log(_ line: String, level: LogLevel) {}
    }

    struct PassthroughInterceptor: RequestInterceptor {
        func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest { request }
    }

    struct WidgetEndpoint: Endpoint {
        typealias Response = [Widget]
        var path = "/widgets"
        var cachePolicy: CachePolicy?
        var deduplicate: Bool?
    }

    static let smallJSON = try! JSONEncoder().encode([Widget(id: 1, name: "alpha", tags: ["a", "b"], active: true)])
    static let largeJSON = try! JSONEncoder().encode(
        (0..<64).map {
            Widget(id: $0, name: "widget-\($0)", tags: ["alpha", "beta", "gamma", "delta"], active: $0 % 2 == 0)
        }
    )

    static func makeClient(
        transport: MockNetworkTransport,
        interceptors: [any RequestInterceptor] = [],
        cache: CacheConfiguration = .disabled,
        deduplicate: Bool = false,
        maxConcurrent: Int = 6
    ) -> NetworkClient {
        var config = NetworkConfiguration(
            environment: NetworkEnvironment(
                kind: .production, baseURL: URL(string: "https://bench.local")!, logLevel: .none),
            logger: SilentLogger(),
            metrics: NoopMetrics(),
            cache: cache,
            maxConcurrentRequests: maxConcurrent,
            enableDeduplication: deduplicate
        )
        config.requestInterceptors = interceptors
        return NetworkClient(configuration: config, transport: transport)
    }

    // MARK: scenarios

    static func all() async -> [BenchmarkResult] {
        var out: [BenchmarkResult] = []

        // 1. Full pipeline overhead: interceptors -> cache check -> auth -> transport -> decode -> metrics.
        let plain = makeClient(transport: MockNetworkTransport(default: .json(smallJSON)))
        out.append(
            await Harness.measureAsync(
                "pipeline_overhead", "Request pipeline overhead", unit: .microseconds, iterations: 4000,
                note: "client.request() end to end, network replaced by MockNetworkTransport"
            ) { _ = try! await plain.request(WidgetEndpoint()) }
        )

        // 2. Same path with 5 interceptors -> the site shows the delta as interceptor cost.
        let withInterceptors = makeClient(
            transport: MockNetworkTransport(default: .json(smallJSON)),
            interceptors: Array(repeating: PassthroughInterceptor(), count: 5)
        )
        out.append(
            await Harness.measureAsync(
                "pipeline_5_interceptors", "Pipeline + 5 interceptors", unit: .microseconds, iterations: 4000,
                note: "same request with a 5-stage interceptor chain"
            ) { _ = try! await withInterceptors.request(WidgetEndpoint()) }
        )

        // 3 & 4. Decoding through the package's configured JSONDecoder.
        let decoder = JSONDecoder.networkKitDefault
        out.append(
            Harness.measure("json_decode_small", "JSON decode (1 object)", unit: .microseconds, iterations: 20000) {
                _ = try! decoder.decode([Widget].self, from: smallJSON)
            }
        )
        out.append(
            Harness.measure("json_decode_large", "JSON decode (64 objects)", unit: .microseconds, iterations: 8000) {
                _ = try! decoder.decode([Widget].self, from: largeJSON)
            }
        )

        // 5 & 6. Cache stores in isolation.
        let mem = MemoryCacheStore()
        let cached = CachedResponse(
            data: largeJSON, headers: ["Content-Type": "application/json"], statusCode: 200, storedAt: Date())
        out.append(
            await Harness.measureAsync(
                "memory_cache_roundtrip", "Memory cache write + read", unit: .microseconds, iterations: 20000
            ) {
                await mem.setValue(cached, forKey: "k")
                _ = await mem.value(forKey: "k")
            }
        )
        let diskDir = FileManager.default.temporaryDirectory.appendingPathComponent("snk-bench-\(UUID().uuidString)")
        let disk = DiskCacheStore(directory: diskDir)
        out.append(
            await Harness.measureAsync(
                "disk_cache_roundtrip", "Disk cache write + read", unit: .microseconds, iterations: 4000
            ) {
                await disk.setValue(cached, forKey: "k")
                _ = await disk.value(forKey: "k")
            }
        )
        try? FileManager.default.removeItem(at: diskDir)

        // 7. A cache-served request: full client path, but the response comes from the store, not transport.
        let cacheStore = MemoryCacheStore()
        let cachedClient = makeClient(
            transport: MockNetworkTransport(default: .json(smallJSON)),
            cache: CacheConfiguration(store: cacheStore, defaultPolicy: .cacheFirst, defaultTTL: 3600)
        )
        _ = try? await cachedClient.request(WidgetEndpoint(cachePolicy: .cacheFirst))  // warm it
        out.append(
            await Harness.measureAsync(
                "cache_served_request", "Cache-served request", unit: .microseconds, iterations: 4000,
                note: "client.request() answered from the response cache (no transport hit)"
            ) { _ = try! await cachedClient.request(WidgetEndpoint(cachePolicy: .cacheFirst)) }
        )

        // 8 & 9. Redaction.
        let redactor = Redactor(redactedBodyKeys: ["password", "token"])
        let headers: HTTPHeaders = [
            "Authorization": "Bearer abc.def.ghi", "Accept": "application/json", "Cookie": "sid=xyz",
            "X-Request-ID": UUID().uuidString, "User-Agent": "bench", "Content-Type": "application/json",
        ]
        out.append(
            Harness.measure("redaction_headers", "Header redaction", unit: .nanoseconds, iterations: 50000) {
                _ = redactor.redact(headers: headers)
            }
        )
        let secretBody = Data(#"{"user":"a","password":"hunter2","token":"t0ken","note":"ok"}"#.utf8)
        out.append(
            Harness.measure("redaction_body", "JSON body redaction", unit: .microseconds, iterations: 20000) {
                _ = redactor.redact(body: secretBody)
            }
        )

        // 10. Request deduplication: N concurrent identical in-flight requests collapse to one transport call.
        out.append(contentsOf: await deduplication())

        // 11. Single-flight token refresh: N concurrent 401s trigger exactly one refresh.
        out.append(await singleFlightRefresh())

        // 12. Metrics event recording throughput.
        let metrics = InMemoryMetrics()
        out.append(
            await Harness.measureAsync(
                "metrics_record", "Metrics event recording", unit: .nanoseconds, iterations: 50000
            ) {
                await metrics.record(.success(RequestID(), duration: .milliseconds(12), status: 200))
            }
        )

        return out
    }

    /// op = "coalesce 150 concurrent identical requests into one 5 ms transport call".
    private static func deduplication() async -> [BenchmarkResult] {
        let fanOut = 150
        let transport = MockNetworkTransport(default: .json(smallJSON), latency: .milliseconds(5))
        let client = makeClient(transport: transport, deduplicate: true, maxConcurrent: fanOut * 2)
        let wall = await Harness.measureAsync(
            "dedup_wall", "Deduplicate \(fanOut) concurrent requests", unit: .milliseconds, iterations: 40, warmup: 3,
            note: "\(fanOut) identical requests in flight at once, one 5 ms backend call"
        ) {
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<fanOut {
                    group.addTask { _ = try? await client.request(WidgetEndpoint(deduplicate: true)) }
                }
            }
        }
        let calls = transport.requestCount
        let ratio = BenchmarkResult(
            id: "dedup_ratio", label: "Requests coalesced per backend call", unit: .ratio, iterations: 0, samples: [],
            note: "\(fanOut * 40) requests issued, \(calls) reached the transport",
            scalar: Double(fanOut * 40) / Double(max(calls, 1))
        )
        return [wall, ratio]
    }

    /// op = "50 concurrent requests hit a 401, exactly one refresh runs, all retry and succeed".
    private static func singleFlightRefresh() async -> BenchmarkResult {
        let fanOut = 50
        actor Counter {
            var n = 0
            func bump() { n += 1 }
        }
        let refreshes = Counter()

        return await Harness.measureAsync(
            "single_flight_refresh", "Single-flight 401 refresh (\(fanOut) concurrent)", unit: .milliseconds,
            iterations: 40, warmup: 3, note: "\(fanOut) parallel 401s, one token refresh, all retried"
        ) {
            let transport = MockNetworkTransport(default: .json(smallJSON))
            transport.stub(
                matching: {
                    $0.value(forHTTPHeaderField: "Authorization") == nil
                        || $0.value(forHTTPHeaderField: "Authorization") == "Bearer stale"
                }, with: .status(401))
            transport.stub(
                matching: { $0.value(forHTTPHeaderField: "Authorization") == "Bearer fresh" }, with: .json(smallJSON))
            let client = NetworkClient(
                configuration: NetworkConfiguration(
                    environment: NetworkEnvironment(
                        kind: .production, baseURL: URL(string: "https://bench.local")!, logLevel: .none),
                    logger: SilentLogger(), metrics: NoopMetrics()
                ),
                transport: transport,
                refresh: { _ in
                    await refreshes.bump()
                    return TokenPair(accessToken: "fresh", refreshToken: "r")
                }
            )
            struct Authed: Endpoint {
                typealias Response = [Widget]
                var path = "/secure"
                var authentication: AuthRequirement { .required }
            }
            await withTaskGroup(of: Void.self) { group in
                for _ in 0..<fanOut {
                    group.addTask { _ = try? await client.request(Authed()) }
                }
            }
        }
    }
}
