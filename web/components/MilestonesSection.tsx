"use client";

import React, { useState } from "react";
import {
  Layers,
  CheckCircle2,
  Shield,
  Zap,
  Lock,
  RefreshCw,
  Eye,
  Wifi,
  UploadCloud,
  HardDrive,
  GitMerge,
  KeyRound,
  Database,
  ListOrdered,
  FlaskConical,
  Sparkles,
  Code2,
  Cpu
} from "lucide-react";

interface Milestone {
  id: string;
  tag: string;
  title: string;
  category: "core" | "auth_security" | "storage_cache" | "concurrency_streams" | "tooling_frameworks";
  summary: string;
  concurrencyModel: string;
  primaryTypes: string[];
  deliverables: string[];
  codeSnippet: string;
}

const MILESTONES: Milestone[] = [
  {
    id: "m0",
    tag: "M0",
    title: "Scaffold & Core Types",
    category: "core",
    summary: "Package scaffold, immutable value-type models, and protocol-oriented Endpoint DSL under Swift 6 strict concurrency.",
    concurrencyModel: "Immutable Sendable Value Types",
    primaryTypes: ["Endpoint", "HTTPMethod", "Scheme", "RequestBody", "NetworkError", "EmptyResponse"],
    deliverables: [
      "Protocol-oriented Endpoint DSL with associated type Response",
      "Sendable RequestBody (Data, JSON, URLEncoded, Multipart)",
      "Strongly typed NetworkError hierarchy with underlying Sendable error boxing",
      "Zero external runtime dependencies"
    ],
    codeSnippet: `struct GetProfileEndpoint: Endpoint {
    typealias Response = UserProfile
    var path: String { "/v1/profile" }
    var method: HTTPMethod { .get }
    var authRequirement: AuthRequirement { .bearer }
}`
  },
  {
    id: "m1",
    tag: "M1",
    title: "Request Pipeline & Transport Layer",
    category: "core",
    summary: "Execution engine routing requests through interceptors, URLSession transport, status validation, and typed JSON decoding.",
    concurrencyModel: "Structured Concurrency (async/await)",
    primaryTypes: ["NetworkClient", "NetworkTransport", "URLSessionTransport", "RequestBuilder"],
    deliverables: [
      "Modular NetworkTransport protocol decoupling network I/O",
      "Thread-safe URLSessionTransport with URLSessionConfiguration injection",
      "NetworkClient async/await primary API and completion-handler backward compatibility shim",
      "Automatic RFC 7231 status code mapping and body error decoding"
    ],
    codeSnippet: `let client = NetworkClient(configuration: .init(baseURL: "https://api.acme.com"))
let profile: UserProfile = try await client.request(GetProfileEndpoint())`
  },
  {
    id: "m2",
    tag: "M2",
    title: "Auth Strategies & Actor TokenManager",
    category: "auth_security",
    summary: "Single-flight token refresh actor with caller deduplication, loop prevention, and hardware-backed Keychain storage.",
    concurrencyModel: "Isolated Swift Actor (TokenManager)",
    primaryTypes: ["TokenManager", "AuthStrategy", "BearerAuth", "APIKeyAuth", "KeychainTokenStorage"],
    deliverables: [
      "Isolated TokenManager actor preventing duplicate 401 refresh stampedes",
      "Thread-safe KeychainTokenStorage with kSecAttrAccessibleAfterFirstUnlock protection",
      "Pluggable AuthStrategy protocols for Bearer, APIKey, Basic, and Custom auth",
      "Infinite refresh loop guards and proactive token expiration detection"
    ],
    codeSnippet: `let tokenManager = TokenManager(
    storage: KeychainTokenStorage(service: "com.acme.app"),
    refreshHandler: { expiredToken in
        try await authClient.refreshToken(expiredToken)
    }
)`
  },
  {
    id: "m3",
    tag: "M3",
    title: "Retry Engine, Backoff & Rate Limiting",
    category: "storage_cache",
    summary: "Configurable exponential backoff with full/equal jitter and strict RFC 6585 HTTP 429 Retry-After header compliance.",
    concurrencyModel: "Pure Sendable Functions & Clocks",
    primaryTypes: ["RetryPolicy", "ExponentialBackoff", "JitterStrategy", "ContinuousClockAdapter"],
    deliverables: [
      "Exponential backoff calculation with full, equal, and decorrelated jitter",
      "Automatic parsing of Retry-After delta-seconds and HTTP-date formats",
      "Idempotency validation ensuring unsafe POST/DELETE requests aren't re-executed unintentionally",
      "NetworkClock abstractions for deterministic unit test time traveling"
    ],
    codeSnippet: `let retryPolicy = RetryPolicy(
    maxRetries: 3,
    backoff: ExponentialBackoff(initialDelay: 0.5, maxDelay: 10.0, jitter: .full),
    retryableStatusCodes: [408, 429, 500, 502, 503, 504]
)`
  },
  {
    id: "m4",
    tag: "M4",
    title: "Observability, Interceptors & Redacting Logger",
    category: "concurrency_streams",
    summary: "Bidirectional request/response interception, correlation trace propagation, metrics collection, and zero-leak PII redaction.",
    concurrencyModel: "@TaskLocal TraceContext + InMemoryMetrics Actor",
    primaryTypes: ["RequestInterceptor", "ResponseInterceptor", "RedactingLogger", "TraceContext", "MetricsCollector"],
    deliverables: [
      "Chainable async RequestInterceptor and ResponseInterceptor pipelines",
      "Regex-driven RedactingLogger masking Bearer tokens, passwords, and credit cards",
      "@TaskLocal TraceContext automatically injecting X-Correlation-ID across task hierarchies",
      "Actor-backed MetricsCollector measuring duration, byte sizes, and status distributions"
    ],
    codeSnippet: `let logger = RedactingLogger(
    rules: RedactionRule.standardRules,
    logLevel: .debug
)
let config = NetworkConfiguration(baseURL: url, logger: logger)`
  },
  {
    id: "m5",
    tag: "M5",
    title: "SSL & SPKI Certificate Pinning",
    category: "auth_security",
    summary: "Subject Public Key Info (SPKI) SHA-256 hash pinning preventing certificate expiration lockouts and MitM attacks.",
    concurrencyModel: "Thread-Safe URLSessionDelegate Bridge",
    primaryTypes: ["SSLPinningConfiguration", "SPKIPinningDelegate", "PinnedCertificate"],
    deliverables: [
      "SPKI SHA-256 public key hash comparison without cert expiration renewals",
      "DER/CER certificate binary bundle pinning support",
      "Development discovery mode for extracting live server public key hashes safely",
      "Native Security.framework integration with zero OpenSSL dependencies"
    ],
    codeSnippet: `let pinning = SSLPinningConfiguration(
    pinnedHashes: [
        "api.acme.com": ["sha256/k2v657xMp4bCWqJaQDZrU3J38RxQL0WPSnguE/9czoq="]
    ],
    allowBackupKeys: true
)`
  },
  {
    id: "m6",
    tag: "M6",
    title: "Connectivity & Reachability Engine",
    category: "concurrency_streams",
    summary: "Real-time network path monitoring over Network.framework NWPathMonitor with AsyncStream broadcasting.",
    concurrencyModel: "NWPathMonitor + AsyncStream Bridge",
    primaryTypes: ["NetworkMonitor", "PathNetworkMonitor", "NetworkStatus", "ConnectionType"],
    deliverables: [
      "Protocol-driven NetworkMonitor with mockable testing doubles",
      "PathNetworkMonitor bridge dispatching NWPath onto Swift AsyncStreams",
      "Cellular, Wi-Fi, Ethernet, Constrained (Low Data Mode), and Expensive detection",
      "Broadcaster actor powering automatic offline queue drainage upon reconnection"
    ],
    codeSnippet: `let monitor = PathNetworkMonitor()
for await status in monitor.statusStream {
    print("Network connected: \\(status.isConnected), type: \\(status.connectionType)")
}`
  },
  {
    id: "m7",
    tag: "M7",
    title: "Multipart Form, Upload & Download Progress",
    category: "concurrency_streams",
    summary: "RFC 7578 multipart/form-data encoding and non-blocking upload/download byte progress streams.",
    concurrencyModel: "AsyncThrowingStream Byte Progress",
    primaryTypes: ["MultipartFormData", "ProgressEvent", "UploadRequest", "DownloadProgressEvent"],
    deliverables: [
      "Memory-safe MultipartFormData streaming files directly from disk",
      "AsyncThrowingStream yielding fractionCompleted and byte offsets in real time",
      "Destination file URL atomic saving for background downloads",
      "Cooperative cancellation propagating down to underlying URLSessionTask"
    ],
    codeSnippet: `for try await event in client.upload(UploadAvatarEndpoint(), from: avatarFileURL) {
    print("Upload progress: \\(Int(event.fractionCompleted * 100))%")
}`
  },
  {
    id: "m8",
    tag: "M8",
    title: "Policy-Driven HTTP Response Caching",
    category: "storage_cache",
    summary: "Two-tier Memory and Disk caching with SHA-256 cache keys, TTL management, and RFC 7234 Cache-Control validation.",
    concurrencyModel: "Isolated Actors (DiskCacheStore & MemoryCacheStore)",
    primaryTypes: ["CachePolicy", "ResponseCache", "DiskCacheStore", "MemoryCacheStore", "CachedResponse"],
    deliverables: [
      "Policies: returnCacheDataElseLoad, returnCacheDataDontLoad, reloadRevalidating",
      "DiskCacheStore with NSFileProtectionCompleteUnlessOpen encryption at rest",
      "HTTP Cache-Control header parsing (max-age, no-cache, no-store, stale-while-revalidate)",
      "LRU eviction and automated expired cache entry pruning"
    ],
    codeSnippet: `let diskCache = DiskCacheStore(storageDirectory: cacheDirURL, maxSizeBytes: 50_000_000)
var endpoint = GetFeedEndpoint()
endpoint.cachePolicy = .returnCacheDataElseLoad`
  },
  {
    id: "m9",
    tag: "M9",
    title: "Request Lifecycle, Deduplication & Priority",
    category: "core",
    summary: "In-flight GET request collapsing, priority-based execution queueing, and string RequestID cancellation registry.",
    concurrencyModel: "Actor RequestDeduplicator + PriorityTaskQueue",
    primaryTypes: ["RequestDeduplicator", "PriorityTaskQueue", "RequestRegistry", "RequestPriority", "RequestID"],
    deliverables: [
      "In-flight deduplicator collapsing simultaneous identical GET requests into 1 network flight",
      "PriorityTaskQueue ensuring critical user interactions execute before background telemetry",
      "RequestRegistry allowing selective cancellation by RequestID",
      "Seamless integration with Swift Task cancellation handlers"
    ],
    codeSnippet: `// 5 concurrent views calling this concurrently will trigger only 1 network flight
let profile = try await client.request(GetProfileEndpoint())`
  },
  {
    id: "m10",
    tag: "M10",
    title: "OAuth 2.0 PKCE Engine",
    category: "auth_security",
    summary: "Full RFC 7636 Proof Key for Code Exchange (PKCE) implementation with SHA-256 code challenge generation and token exchange.",
    concurrencyModel: "CryptoKit Hardware-Accelerated SHA-256",
    primaryTypes: ["AuthorizationCodeFlow", "PKCEChallenge", "TokenResponse", "TokenPair"],
    deliverables: [
      "High-entropy cryptographically secure code verifier generator",
      "Base64URL-encoded SHA-256 code challenge computation",
      "State parameter generation and cross-site verification to prevent CSRF attacks",
      "Seamless tokenManagerRefreshHandler integration with TokenManager"
    ],
    codeSnippet: `let oauth = AuthorizationCodeFlow(
    clientId: "acme-mobile-app",
    authorizeURL: URL(string: "https://auth.acme.com/oauth/authorize")!,
    tokenURL: URL(string: "https://auth.acme.com/oauth/token")!,
    redirectURI: URL(string: "acmeapp://oauth-callback")!,
    scopes: ["openid", "profile", "offline_access"]
)`
  },
  {
    id: "m11",
    tag: "M11",
    title: "Persisted Offline Request Queue",
    category: "storage_cache",
    summary: "Disk-persisted FIFO request spooling with automatic background replay when network connectivity is restored.",
    concurrencyModel: "Isolated Actor (OfflineRequestQueue)",
    primaryTypes: ["OfflineRequestQueue", "OfflineStore", "FileOfflineStore", "QueuedRequest"],
    deliverables: [
      "Persistent JSON disk storage surviving application restarts",
      "Topological FIFO ordering for dependent create/update/delete operations",
      "Automatic replay triggered via NetworkMonitor reconnection events",
      "Replay event stream yielding success/failure notifications per queued item"
    ],
    codeSnippet: `let offlineQueue = OfflineRequestQueue(
    store: FileOfflineStore(),
    client: client,
    monitor: monitor
)
let queueID = try await offlineQueue.enqueue(CreateCommentEndpoint(text: "Hello"))`
  },
  {
    id: "m12",
    tag: "M12",
    title: "AsyncSequence Pagination & Parallel Batching",
    category: "concurrency_streams",
    summary: "Cursor and offset-based pagination over Swift AsyncSequence, plus parallel TaskGroup batch execution.",
    concurrencyModel: "TaskGroup + AsyncSequence Streams",
    primaryTypes: ["PaginatedEndpoint", "PageCursor", "ParallelBatchRunner"],
    deliverables: [
      "PaginatedEndpoint protocol defining nextEndpoint(after:) cursor mapping",
      "AsyncThrowingStream yielding page arrays or individual items lazily",
      "client.batch() executing multiple endpoints concurrently with bounded concurrency limits",
      "Zip utilities combining heterogeneous endpoints with type safety"
    ],
    codeSnippet: `for try await usersPage in client.paginate(ListUsersEndpoint(limit: 50)) {
    print("Received page with \\(usersPage.count) users")
}`
  },
  {
    id: "m13",
    tag: "M13",
    title: "Test Doubles, Stubs & Mock Scenarios",
    category: "tooling_frameworks",
    summary: "Built-in, zero-flakiness mock transport, URLProtocol interceptors, and scenario matchers shipped directly in package.",
    concurrencyModel: "Thread-Safe Mock Transport Isolation",
    primaryTypes: ["MockNetworkTransport", "MockURLProtocol", "MockScenario", "RequestMatcher"],
    deliverables: [
      "MockNetworkTransport eliminating network socket dependencies in unit tests",
      "Stub registration by Endpoint type, URL pattern, or custom predicate matcher",
      "Recorded request verification for headers, query items, and JSON body payloads",
      "Simulated latency, HTTP status codes, and network error injection"
    ],
    codeSnippet: `@Test func testProfileFetch() async throws {
    let mock = MockNetworkTransport()
    mock.registerStub(for: GetProfileEndpoint.self, result: .success(UserProfile.fixture))
    let client = NetworkClient(configuration: .mock, transport: mock)
    let profile = try await client.request(GetProfileEndpoint())
    #expect(profile.name == "Ada Lovelace")
}`
  },
  {
    id: "m14",
    tag: "M14",
    title: "Combine Publishers & SwiftUI @Observable",
    category: "tooling_frameworks",
    summary: "Opt-in Combine publishers and iOS 17+ @Observable load state holders with pull-to-refresh and lifecycle integration.",
    concurrencyModel: "@MainActor + Observation Framework",
    primaryTypes: ["NetworkResource", "LoadState", "Paged", "AnyPublisher"],
    deliverables: [
      "Combine publisher(for:), uploadPublisher, and downloadPublisher extensions",
      "@Observable @MainActor NetworkResource<T> managing .idle, .loading, .success, .failure states",
      "Paged<Item> wrapper for SwiftUI List pagination with infinite scroll triggers",
      "Gated via #if canImport(Observation) and #if canImport(Combine) to keep core zero-dependency"
    ],
    codeSnippet: `@Observable
@MainActor
final class ProfileViewModel {
    let resource: NetworkResource<UserProfile>
    init(client: NetworkClient) {
        self.resource = NetworkResource(client: client)
    }
    func load() async {
        await resource.load(GetProfileEndpoint())
    }
}`
  }
];

function MilestoneIcon({ id, className = "w-4 h-4" }: { id: string; className?: string }) {
  switch (id) {
    case "m0":
      return <Layers className={className} />;
    case "m1":
      return <Zap className={className} />;
    case "m2":
      return <Lock className={className} />;
    case "m3":
      return <RefreshCw className={className} />;
    case "m4":
      return <Eye className={className} />;
    case "m5":
      return <Shield className={className} />;
    case "m6":
      return <Wifi className={className} />;
    case "m7":
      return <UploadCloud className={className} />;
    case "m8":
      return <HardDrive className={className} />;
    case "m9":
      return <GitMerge className={className} />;
    case "m10":
      return <KeyRound className={className} />;
    case "m11":
      return <Database className={className} />;
    case "m12":
      return <ListOrdered className={className} />;
    case "m13":
      return <FlaskConical className={className} />;
    case "m14":
      return <Sparkles className={className} />;
    default:
      return <Cpu className={className} />;
  }
}

export function MilestonesSection() {
  const [selectedCategory, setSelectedCategory] = useState<string>("all");
  const [activeMilestoneId, setActiveMilestoneId] = useState<string>("m0");

  const categories = [
    { id: "all", label: "All 15 Milestones (M0-M14)" },
    { id: "core", label: "Core & Pipeline" },
    { id: "auth_security", label: "Auth & Security" },
    { id: "storage_cache", label: "Storage & Resilience" },
    { id: "concurrency_streams", label: "Async & Streams" },
    { id: "tooling_frameworks", label: "Tooling & SwiftUI" },
  ];

  const filtered = MILESTONES.filter(
    (m) => selectedCategory === "all" || m.category === selectedCategory
  );

  const activeMilestone =
    MILESTONES.find((m) => m.id === activeMilestoneId) || MILESTONES[0];

  return (
    <section id="milestones" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 text-xs font-semibold mb-3 font-mono">
          <Cpu className="w-3.5 h-3.5" /> ARCHITECTURE CHRONOLOGY
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          The 14-Milestone Engineering Blueprint
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Explore the complete architectural progression of SwiftNetworkKit from zero-scaffold foundations to production-grade enterprise concurrency.
        </p>
      </div>

      {/* Category Pills */}
      <div className="flex flex-wrap items-center justify-center gap-2 mb-10">
        {categories.map((cat) => (
          <button
            key={cat.id}
            onClick={() => {
              setSelectedCategory(cat.id);
              const firstMatch = MILESTONES.find(
                (m) => cat.id === "all" || m.category === cat.id
              );
              if (firstMatch) setActiveMilestoneId(firstMatch.id);
            }}
            className={`px-3.5 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
              selectedCategory === cat.id
                ? "bg-orange-600 text-white shadow-md shadow-orange-600/20"
                : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 border border-slate-200 dark:border-white/10"
            }`}
          >
            {cat.label}
          </button>
        ))}
      </div>

      {/* Main Grid: Left selector timeline, Right detail view */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left Column: Milestone List */}
        <div className="lg:col-span-5 space-y-2.5 max-h-[680px] overflow-y-auto pr-2 custom-scrollbar">
          {filtered.map((m) => {
            const isActive = m.id === activeMilestone.id;
            return (
              <button
                key={m.id}
                onClick={() => setActiveMilestoneId(m.id)}
                className={`w-full text-left p-4 rounded-xl transition-all duration-200 flex items-center justify-between gap-4 border cursor-pointer ${
                  isActive
                    ? "bg-orange-500/10 dark:bg-orange-500/15 border-orange-500/50 dark:border-orange-500/40 shadow-sm"
                    : "bg-white/80 dark:bg-slate-900/60 border-slate-200 dark:border-white/5 hover:border-slate-300 dark:hover:border-white/20"
                }`}
              >
                <div className="flex items-center gap-3 min-w-0">
                  <div
                    className={`w-9 h-9 rounded-lg flex items-center justify-center shrink-0 ${
                      isActive
                        ? "bg-orange-600 text-white shadow-sm"
                        : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400"
                    }`}
                  >
                    <MilestoneIcon id={m.id} className="w-4 h-4" />
                  </div>
                  <div className="truncate">
                    <div className="flex items-center gap-2">
                      <span className="text-xs font-mono font-bold text-orange-600 dark:text-orange-400">
                        {m.tag}
                      </span>
                      <span className="text-sm font-bold text-slate-900 dark:text-slate-100 truncate">
                        {m.title}
                      </span>
                    </div>
                    <p className="text-xs text-slate-500 dark:text-slate-400 truncate mt-0.5 font-mono">
                      {m.concurrencyModel}
                    </p>
                  </div>
                </div>

                <div className="shrink-0 flex items-center gap-1.5 text-emerald-600 dark:text-emerald-400 text-xs font-mono font-semibold">
                  <CheckCircle2 className="w-4 h-4" />
                  <span className="hidden sm:inline">v0.1.0</span>
                </div>
              </button>
            );
          })}
        </div>

        {/* Right Column: Active Milestone Deep Dive */}
        <div className="lg:col-span-7 glass-panel p-6 sm:p-8 bg-white/95 dark:bg-slate-900/90 border border-slate-200 dark:border-white/10 rounded-2xl shadow-xl">
          <div className="flex flex-wrap items-center justify-between gap-3 pb-4 mb-6 border-b border-slate-200 dark:border-white/10">
            <div className="flex items-center gap-3">
              <div className="w-10 h-10 rounded-xl bg-orange-600 text-white flex items-center justify-center shadow-md">
                <MilestoneIcon id={activeMilestone.id} className="w-5 h-5" />
              </div>
              <div>
                <div className="flex items-center gap-2">
                  <span className="text-xs font-mono font-extrabold px-2 py-0.5 rounded bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20">
                    Milestone {activeMilestone.tag}
                  </span>
                  <span className="text-xs font-mono text-emerald-600 dark:text-emerald-400 font-bold flex items-center gap-1">
                    <CheckCircle2 className="w-3.5 h-3.5" /> Complete
                  </span>
                </div>
                <h3 className="text-xl font-bold text-slate-900 dark:text-white mt-1">
                  {activeMilestone.title}
                </h3>
              </div>
            </div>

            <div className="text-right">
              <span className="text-xs font-mono px-2.5 py-1 rounded bg-slate-100 dark:bg-slate-800 text-slate-700 dark:text-slate-300 border border-slate-200 dark:border-slate-700 font-semibold">
                {activeMilestone.concurrencyModel}
              </span>
            </div>
          </div>

          <p className="text-sm text-slate-700 dark:text-slate-300 leading-relaxed mb-6 font-medium">
            {activeMilestone.summary}
          </p>

          {/* Primary Types */}
          <div className="mb-6">
            <h4 className="text-xs font-bold font-mono text-slate-500 uppercase tracking-wider mb-2">
              Primary Public Types Introduced
            </h4>
            <div className="flex flex-wrap gap-1.5">
              {activeMilestone.primaryTypes.map((t, idx) => (
                <span
                  key={idx}
                  className="px-2.5 py-1 rounded-md bg-sky-500/10 text-sky-700 dark:text-sky-300 border border-sky-500/20 text-xs font-mono font-semibold"
                >
                  {t}
                </span>
              ))}
            </div>
          </div>

          {/* Deliverables Checklist */}
          <div className="mb-6">
            <h4 className="text-xs font-bold font-mono text-slate-500 uppercase tracking-wider mb-2.5">
              Key Engineering Deliverables
            </h4>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-2.5">
              {activeMilestone.deliverables.map((item, idx) => (
                <div
                  key={idx}
                  className="p-3 rounded-lg bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800/80 flex items-start gap-2 text-xs text-slate-700 dark:text-slate-300"
                >
                  <CheckCircle2 className="w-3.5 h-3.5 text-emerald-500 shrink-0 mt-0.5" />
                  <span>{item}</span>
                </div>
              ))}
            </div>
          </div>

          {/* Code Snippet */}
          <div>
            <div className="flex items-center justify-between mb-2">
              <h4 className="text-xs font-bold font-mono text-slate-500 uppercase tracking-wider flex items-center gap-1.5">
                <Code2 className="w-3.5 h-3.5 text-orange-500" />
                Swift 6 Implementation Pattern
              </h4>
            </div>
            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-xs font-mono text-slate-200 overflow-x-auto shadow-inner">
              <pre className="whitespace-pre">
                <code>{activeMilestone.codeSnippet}</code>
              </pre>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
