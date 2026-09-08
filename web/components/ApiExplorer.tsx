"use client";

import React, { useState } from "react";
import { BookOpen, Search, Copy, Check, ExternalLink, Code2, ShieldAlert, Cpu } from "lucide-react";

interface ApiItem {
  name: string;
  category:
    | "core"
    | "auth"
    | "oauth"
    | "security"
    | "cache"
    | "offline"
    | "retry"
    | "observability"
    | "connectivity"
    | "transfers"
    | "concurrency"
    | "pagination"
    | "testing"
    | "swiftui";
  type: string;
  signature: string;
  isolation: string;
  summary: string;
  parameters?: { name: string; type: string; desc: string }[];
  returns?: string;
  code: string;
}

const API_SYMBOLS: ApiItem[] = [
  {
    name: "NetworkClient",
    category: "core",
    type: "Class",
    signature: "public final class NetworkClient: Sendable",
    isolation: "Sendable / Structured Concurrency",
    summary: "The main networking orchestrator. Dispatches requests through interceptors, URLSession transport, actor token refresh loops, two-tier cache stores, and metrics collectors.",
    parameters: [
      { name: "configuration", type: "NetworkConfiguration", desc: "Base URL, timeout, headers, retry, and pinning setup." },
      { name: "transport", type: "NetworkTransport", desc: "Network I/O transport (defaults to URLSessionTransport)." },
      { name: "tokenManager", type: "TokenManager?", desc: "Optional actor for single-flight 401 token refreshes." },
      { name: "metricsCollector", type: "MetricsCollector?", desc: "Optional metrics sink for request timing telemetry." }
    ],
    returns: "E.Response (decoded conforming type)",
    code: `let config = NetworkConfiguration(baseURL: "https://api.acme.com")
let client = NetworkClient(configuration: config)
let profile: UserProfile = try await client.request(GetProfileEndpoint())`
  },
  {
    name: "Endpoint",
    category: "core",
    type: "Protocol",
    signature: "public protocol Endpoint: Sendable",
    isolation: "Immutable Sendable Value",
    summary: "Protocol defining a type-safe HTTP request with an associated Decodable response type, path, method, headers, query items, body, and policies.",
    returns: "Associatedtype Response: Decodable & Sendable",
    code: `struct ListUsersEndpoint: Endpoint {
    typealias Response = [User]
    var path: String { "/v1/users" }
    var method: HTTPMethod { .get }
    var queryItems: [URLQueryItem]? { [URLQueryItem(name: "limit", value: "25")] }
    var authRequirement: AuthRequirement { .bearer }
}`
  },
  {
    name: "NetworkConfiguration",
    category: "core",
    type: "Struct",
    signature: "public struct NetworkConfiguration: Sendable",
    isolation: "Sendable Value Type",
    summary: "Central configuration holding base URL, default headers, timeout intervals, retry policies, SSL pinning, cache configuration, and logging.",
    code: `var config = NetworkConfiguration(baseURL: "https://api.acme.com")
config.timeoutInterval = 30.0
config.retry = .standard
config.cache = CacheConfiguration(store: DiskCacheStore(), defaultPolicy: .returnCacheDataElseLoad)
config.sslPinning = .publicKeys(["sha256/k2v657xMp4bCWqJaQDZrU3J38RxQL0WPSnguE/9czoq="])`
  },
  {
    name: "RequestBody",
    category: "core",
    type: "Enum",
    signature: "public enum RequestBody: Sendable",
    isolation: "Sendable Value Type",
    summary: "Encapsulates payload serialization for JSON, binary raw data, URL-encoded form data, and multipart streaming uploads.",
    code: `// JSON payload with custom encoder
var body = RequestBody.json(DraftPost(title: "Hello World"))

// Multipart payload
var body = RequestBody.multipart(form)`
  },
  {
    name: "NetworkError",
    category: "core",
    type: "Enum / Error",
    signature: "public enum NetworkError: Error, Sendable, Equatable",
    isolation: "Sendable Value Type",
    summary: "Strongly typed error enum covering encoding/decoding failures, transport errors, HTTP non-2xx status codes, rate limiting, and SSL pinning rejections.",
    code: `do {
    let result = try await client.request(endpoint)
} catch let NetworkError.httpError(statusCode, data, context) {
    print("HTTP \\(statusCode) failed on \\(context.requestURL)")
} catch NetworkError.sslPinningFailed(let host) {
    print("Untrusted certificate on \\(host)")
}`
  },
  {
    name: "TokenManager",
    category: "auth",
    type: "Actor",
    signature: "public actor TokenManager",
    isolation: "Isolated Swift Actor",
    summary: "Thread-safe actor managing single-flight 401 refresh token exchanges, caller queueing, refresh loops guards, and proactive expiration renewal.",
    parameters: [
      { name: "storage", type: "TokenStorage", desc: "Hardware Keychain or memory persistence." },
      { name: "refreshHandler", type: "@Sendable (String) async throws -> TokenPair", desc: "Closure executing token refresh against OAuth server." }
    ],
    code: `let manager = TokenManager(
    storage: KeychainTokenStorage(service: "com.acme.app"),
    refreshHandler: { expiredToken in
        try await authClient.refreshToken(expiredToken)
    }
)
let token = try await manager.validAccessToken()`
  },
  {
    name: "KeychainTokenStorage",
    category: "auth",
    type: "Class",
    signature: "public final class KeychainTokenStorage: TokenStorage, @unchecked Sendable",
    isolation: "Thread-Safe Keychain Bridge",
    summary: "Production iOS/macOS Keychain storage for TokenPair with device-only kSecAttrAccessibleAfterFirstUnlock protection.",
    code: `let storage = KeychainTokenStorage(
    service: "com.acme.app",
    accessibility: .afterFirstUnlockThisDeviceOnly
)`
  },
  {
    name: "BearerAuth",
    category: "auth",
    type: "Struct",
    signature: "public struct BearerAuth: AuthStrategy",
    isolation: "Sendable",
    summary: "AuthStrategy injecting Authorization: Bearer <token> into outgoing URLRequests via an asynchronous token provider.",
    code: `let auth = BearerAuth {
    try await tokenManager.validAccessToken()
}`
  },
  {
    name: "AuthorizationCodeFlow",
    category: "oauth",
    type: "Struct",
    signature: "public struct AuthorizationCodeFlow: Sendable",
    isolation: "Sendable / CryptoKit SHA-256",
    summary: "OAuth 2.0 RFC 7636 Authorization Code flow with PKCE. Generates authorization URLs, computes SHA-256 code verifiers, and exchanges tokens.",
    code: `let flow = AuthorizationCodeFlow(
    clientId: "mobile-client",
    authorizeURL: URL(string: "https://auth.acme.com/authorize")!,
    tokenURL: URL(string: "https://auth.acme.com/token")!,
    redirectURI: URL(string: "acme://callback")!,
    scopes: ["openid", "profile", "offline_access"]
)
let (authURL, verifier, state) = flow.makeAuthorizationURL()`
  },
  {
    name: "SSLPinningConfiguration",
    category: "security",
    type: "Struct",
    signature: "public struct SSLPinningConfiguration: Sendable",
    isolation: "Sendable Value",
    summary: "Subject Public Key Info (SPKI) SHA-256 hash pinning preventing certificate expiration lockouts while securing against MitM interception.",
    code: `let pinning = SSLPinningConfiguration(
    pinnedHashes: [
        "api.acme.com": ["sha256/k2v657xMp4bCWqJaQDZrU3J38RxQL0WPSnguE/9czoq="]
    ],
    allowBackupKeys: true
)`
  },
  {
    name: "SPKIPinningDelegate",
    category: "security",
    type: "Class",
    signature: "public final class SPKIPinningDelegate: NSObject, URLSessionDelegate, @unchecked Sendable",
    isolation: "URLSession Delegate Region",
    summary: "Custom URLSessionDelegate validating server leaf certificate SPKI hashes against configured SHA-256 fingerprints before connection handshake.",
    code: `let delegate = SPKIPinningDelegate(pinnedHashes: ["api.acme.com": [hash1, hash2]])
let session = URLSession(configuration: .default, delegate: delegate, delegateQueue: nil)`
  },
  {
    name: "DiskCacheStore",
    category: "cache",
    type: "Actor",
    signature: "public actor DiskCacheStore: CacheStore",
    isolation: "Isolated Swift Actor",
    summary: "Disk-backed LRU HTTP response cache. Encrypted at rest with NSFileProtectionCompleteUnlessOpen. Validates Cache-Control max-age and ETag 304.",
    parameters: [
      { name: "storageDirectory", type: "URL", desc: "Directory where cached binary files and headers reside." },
      { name: "maxSizeBytes", type: "Int", desc: "Maximum disk budget (defaults to 50 MB) before LRU eviction." },
      { name: "defaultTTL", type: "TimeInterval", desc: "Default time to live in seconds when Cache-Control is absent." }
    ],
    code: `let diskCache = DiskCacheStore(storageDirectory: cacheDirURL, maxSizeBytes: 50_000_000, defaultTTL: 300)
await diskCache.set(cachedResponse, key: "sha256_hash")`
  },
  {
    name: "CachePolicy",
    category: "cache",
    type: "Enum",
    signature: "public enum CachePolicy: Sendable",
    isolation: "Sendable Value",
    summary: "Deterministic caching strategies for requests.",
    code: `public enum CachePolicy {
    case returnCacheDataElseLoad
    case returnCacheDataDontLoad
    case reloadIgnoringLocalCacheData
    case reloadRevalidatingCacheData
}`
  },
  {
    name: "OfflineRequestQueue",
    category: "offline",
    type: "Actor",
    signature: "public actor OfflineRequestQueue",
    isolation: "Isolated Swift Actor",
    summary: "Persisted offline request queue. Spools non-idempotent write endpoints to disk when disconnected and automatically drains FIFO upon network reconnection.",
    code: `let offlineQueue = OfflineRequestQueue(store: FileOfflineStore(), client: client, monitor: monitor)
let queueID = try await offlineQueue.enqueue(CreateOrderEndpoint(order: newOrder))`
  },
  {
    name: "FileOfflineStore",
    category: "offline",
    type: "Actor",
    signature: "public actor FileOfflineStore: OfflineStore",
    isolation: "Isolated Swift Actor",
    summary: "File-system backed offline store saving serialized endpoints in an encrypted JSON format across application terminations.",
    code: `let store = FileOfflineStore(directory: offlineSpoolURL)`
  },
  {
    name: "RetryPolicy",
    category: "retry",
    type: "Struct",
    signature: "public struct RetryPolicy: Sendable",
    isolation: "Sendable Value",
    summary: "Configures maximum retry attempts, exponential backoff curves, full/equal jitter, and HTTP 429 Retry-After compliance.",
    code: `let policy = RetryPolicy(
    maxRetries: 3,
    backoff: ExponentialBackoff(initialDelay: 0.5, maxDelay: 8.0, jitter: .full),
    retryableStatusCodes: [408, 429, 500, 502, 503, 504]
)`
  },
  {
    name: "RedactingLogger",
    category: "observability",
    type: "Struct",
    signature: "public struct RedactingLogger: Sendable",
    isolation: "Sendable Value",
    summary: "High-performance structured logger with automated regex redaction for Bearer tokens, passwords, credit card numbers, and PII.",
    code: `let logger = RedactingLogger(
    rules: RedactionRule.standardRules,
    logLevel: .debug
)`
  },
  {
    name: "PathNetworkMonitor",
    category: "connectivity",
    type: "Class",
    signature: "public final class PathNetworkMonitor: NetworkMonitor, Sendable",
    isolation: "NWPathMonitor + AsyncStream",
    summary: "Real-time network reachability monitor wrapping Apple Network.framework NWPathMonitor, broadcasting status changes over an AsyncStream.",
    code: `let monitor = PathNetworkMonitor()
for await status in monitor.statusStream {
    if status.isConnected {
        print("Connected via \\(status.connectionType)")
    }
}`
  },
  {
    name: "MultipartFormData",
    category: "transfers",
    type: "Struct",
    signature: "public struct MultipartFormData: Sendable",
    isolation: "Sendable Value",
    summary: "RFC 7578 compliant multipart/form-data generator. Streams large binary files directly from disk without exhausting memory.",
    code: `var form = MultipartFormData()
form.append(value: "Husnain", name: "author")
form.append(fileData: imageBytes, name: "avatar", fileName: "profile.png", mimeType: "image/png")
let (bodyData, boundary) = form.build()`
  },
  {
    name: "ProgressEvent",
    category: "transfers",
    type: "Struct",
    signature: "public struct ProgressEvent<T: Sendable>: Sendable",
    isolation: "Sendable Value",
    summary: "Asynchronous progress notification containing fractionCompleted, bytesTransferred, totalBytes, and optional final decoded response.",
    code: `for try await event in client.upload(UploadAvatarEndpoint(), from: avatarFileURL) {
    print("Uploaded \\(event.bytesTransferred) of \\(event.totalBytes) bytes (\\(Int(event.fractionCompleted * 100))%)")
}`
  },
  {
    name: "RequestDeduplicator",
    category: "concurrency",
    type: "Actor",
    signature: "public actor RequestDeduplicator",
    isolation: "Isolated Swift Actor",
    summary: "In-flight request deduplicator coalescing concurrent, identical idempotent GET requests onto a single in-flight network Task.",
    code: `// Executing 10 parallel calls to the same endpoint produces exactly 1 network flight
async let u1 = client.request(GetProfileEndpoint())
async let u2 = client.request(GetProfileEndpoint())`
  },
  {
    name: "PriorityTaskQueue",
    category: "concurrency",
    type: "Actor",
    signature: "public actor PriorityTaskQueue",
    isolation: "Isolated Swift Actor",
    summary: "Actor-isolated priority scheduler executing .urgent and .high priority network tasks ahead of background telemetry .low priority tasks.",
    code: `var endpoint = CheckoutOrderEndpoint()
endpoint.priority = .urgent`
  },
  {
    name: "PaginatedEndpoint",
    category: "pagination",
    type: "Protocol",
    signature: "public protocol PaginatedEndpoint: Endpoint",
    isolation: "Sendable Value",
    summary: "Protocol declaring paginated APIs. Provides nextEndpoint(after:) mapping to yield an infinite AsyncThrowingStream of items or pages.",
    code: `for try await page in client.paginate(ListTransactionsEndpoint(cursor: nil)) {
    print("Page received with \\(page.count) items")
}`
  },
  {
    name: "MockNetworkTransport",
    category: "testing",
    type: "Class",
    signature: "public final class MockNetworkTransport: NetworkTransport, @unchecked Sendable",
    isolation: "Thread-Safe In-Memory Seam",
    summary: "Comprehensive test double shipping inside the package. Register stubs by Endpoint type, HTTP status, or URLRequest predicates without network flakiness.",
    code: `let mock = MockNetworkTransport()
mock.registerStub(for: GetProfileEndpoint.self, result: .success(UserProfile.mock))
let client = NetworkClient(configuration: .mock, transport: mock)`
  },
  {
    name: "NetworkResource",
    category: "swiftui",
    type: "Class / @Observable",
    signature: "@Observable @MainActor public final class NetworkResource<Value: Sendable>",
    isolation: "@MainActor (iOS 17+ Observation)",
    summary: "SwiftUI observable state container managing async loading, reload/refresh, and binding states (.idle, .loading, .success, .failure).",
    code: `@Observable @MainActor
final class ProfileViewModel {
    let user = NetworkResource<UserProfile>(client: client)
    
    func onAppear() async {
        await user.load(GetProfileEndpoint())
    }
}`
  }
];

export function ApiExplorer() {
  const [category, setCategory] = useState<string>("all");
  const [search, setSearch] = useState<string>("");
  const [copiedIndex, setCopiedIndex] = useState<number | null>(null);

  const categories = [
    { id: "all", label: "All Symbols" },
    { id: "core", label: "Core DSL" },
    { id: "auth", label: "Auth & Tokens" },
    { id: "oauth", label: "OAuth PKCE" },
    { id: "security", label: "TLS & SPKI" },
    { id: "cache", label: "Caching" },
    { id: "offline", label: "Offline Queue" },
    { id: "retry", label: "Retry Engine" },
    { id: "observability", label: "Logging & Interceptors" },
    { id: "connectivity", label: "Reachability" },
    { id: "transfers", label: "Upload & Download" },
    { id: "concurrency", label: "Actors & Priority" },
    { id: "pagination", label: "Pagination" },
    { id: "testing", label: "Test Doubles" },
    { id: "swiftui", label: "SwiftUI & Combine" }
  ];

  const filtered = API_SYMBOLS.filter((item) => {
    const matchCat = category === "all" || item.category === category;
    const matchSearch =
      search === "" ||
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.signature.toLowerCase().includes(search.toLowerCase()) ||
      item.summary.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  const handleCopy = (code: string, index: number) => {
    navigator.clipboard.writeText(code);
    setCopiedIndex(index);
    setTimeout(() => setCopiedIndex(null), 2000);
  };

  return (
    <section id="api-reference" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-14">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-sky-500/10 text-sky-700 dark:text-sky-400 border border-sky-500/20 text-xs font-semibold mb-3 font-mono">
          <BookOpen className="w-3.5 h-3.5" /> TYPE DICTIONARY & API REFERENCE
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Comprehensive Public API Reference
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Explore complete Swift 6 signatures, actor isolation constraints, parameter tables, and copy-pasteable usage examples across all package modules.
        </p>
      </div>

      {/* Search & Category Filter */}
      <div className="space-y-4 mb-10">
        <div className="max-w-xl mx-auto relative">
          <Search className="w-4 h-4 text-slate-400 absolute left-4 top-3.5" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Filter by symbol, struct, actor, or keyword (e.g. TokenManager, DiskCacheStore)..."
            className="w-full pl-11 pr-4 py-3 rounded-2xl bg-white dark:bg-slate-900/90 border border-slate-200 dark:border-white/10 text-sm text-slate-900 dark:text-slate-100 placeholder-slate-400 focus:border-sky-500 focus:outline-none font-mono shadow-sm"
          />
        </div>

        <div className="flex flex-wrap items-center justify-center gap-1.5">
          {categories.map((cat) => (
            <button
              key={cat.id}
              onClick={() => setCategory(cat.id)}
              className={`px-3 py-1.5 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                category === cat.id
                  ? "bg-sky-600 text-white shadow-md shadow-sky-600/20"
                  : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 border border-slate-200 dark:border-white/5"
              }`}
            >
              {cat.label}
            </button>
          ))}
        </div>
      </div>

      {/* Results Count & Link */}
      <div className="flex items-center justify-between mb-6 text-xs font-mono text-slate-500">
        <span>Showing {filtered.length} of {API_SYMBOLS.length} documented public symbols</span>
        <a
          href="https://github.com/ihusnainalii/SwiftNetworkKit/blob/main/Documentation/APIReference.md"
          target="_blank"
          rel="noreferrer"
          className="text-sky-600 dark:text-sky-400 hover:underline flex items-center gap-1 font-semibold"
        >
          <span>View Markdown Reference in Repo</span>
          <ExternalLink className="w-3 h-3" />
        </a>
      </div>

      {/* Symbols Grid */}
      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {filtered.map((item, i) => (
          <div
            key={i}
            className="glass-panel p-6 sm:p-7 flex flex-col justify-between bg-white/95 dark:bg-slate-900/80 shadow-xl border border-slate-200 dark:border-white/10 rounded-2xl hover:border-sky-500/40 transition-all duration-300"
          >
            <div>
              <div className="flex items-center justify-between gap-2 mb-3">
                <div className="flex items-center gap-2">
                  <span className="text-xs font-mono px-2.5 py-0.5 rounded-md bg-sky-500/10 text-sky-700 dark:text-sky-400 border border-sky-500/20 font-bold">
                    {item.type}
                  </span>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400">
                    {item.isolation}
                  </span>
                </div>
                <span className="text-[10px] font-mono text-slate-400 uppercase tracking-wider">
                  {item.category}
                </span>
              </div>

              <h3 className="text-xl font-bold font-mono text-slate-900 dark:text-white mb-2">
                {item.name}
              </h3>

              <p className="text-xs text-slate-600 dark:text-slate-400 mb-4 leading-relaxed">
                {item.summary}
              </p>

              {/* Signature Box */}
              <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs text-sky-300 overflow-x-auto mb-4">
                <pre className="whitespace-pre">
                  <code>{item.signature}</code>
                </pre>
              </div>

              {/* Parameters List if available */}
              {item.parameters && item.parameters.length > 0 && (
                <div className="mb-4 space-y-1.5">
                  <span className="text-[11px] font-mono font-bold text-slate-500 uppercase tracking-wider block">
                    Parameters
                  </span>
                  <div className="space-y-1">
                    {item.parameters.map((p, pIdx) => (
                      <div key={pIdx} className="text-xs font-mono flex items-start gap-2 text-slate-700 dark:text-slate-300">
                        <span className="text-sky-600 dark:text-sky-400 font-bold shrink-0">{p.name}:</span>
                        <span className="text-slate-500 dark:text-slate-400 shrink-0 font-light">({p.type})</span>
                        <span className="text-slate-600 dark:text-slate-400 text-[11px] truncate">{p.desc}</span>
                      </div>
                    ))}
                  </div>
                </div>
              )}
            </div>

            {/* Code Usage Box */}
            <div className="mt-2">
              <div className="flex items-center justify-between pb-1.5 text-xs text-slate-400 font-mono">
                <span className="flex items-center gap-1">
                  <Code2 className="w-3.5 h-3.5 text-sky-500" />
                  Swift Example
                </span>
                <button
                  onClick={() => handleCopy(item.code, i)}
                  className="flex items-center gap-1 text-[11px] text-slate-500 hover:text-slate-900 dark:hover:text-white transition-colors cursor-pointer"
                >
                  {copiedIndex === i ? (
                    <>
                      <Check className="w-3 h-3 text-emerald-500" />
                      <span className="text-emerald-500">Copied</span>
                    </>
                  ) : (
                    <>
                      <Copy className="w-3 h-3" />
                      <span>Copy</span>
                    </>
                  )}
                </button>
              </div>
              <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs text-slate-200 overflow-x-auto shadow-inner">
                <pre className="whitespace-pre font-mono">
                  <code>{item.code}</code>
                </pre>
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
