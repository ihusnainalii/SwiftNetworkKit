"use client";

import React, { useState } from "react";
import { BookOpen, Search } from "lucide-react";

interface ApiItem {
  name: string;
  category: "core" | "auth" | "oauth" | "cache" | "offline" | "retry" | "security" | "connectivity" | "upload" | "pagination" | "swiftui" | "testing";
  type: string;
  signature: string;
  summary: string;
  code: string;
}

const API_SYMBOLS: ApiItem[] = [
  {
    name: "NetworkClient",
    category: "core",
    type: "Class / Sendable",
    signature: "public final class NetworkClient: Sendable",
    summary: "The main networking engine. Manages request dispatching, URLSession transport lifecycle, actor token refresh loops, caching, and metrics sinks.",
    code: `let client = NetworkClient(configuration: config, refresh: { ... })
let user: User = try await client.request(GetProfile())`,
  },
  {
    name: "Endpoint",
    category: "core",
    type: "Protocol",
    signature: "public protocol Endpoint: Sendable",
    summary: "Protocol declaring an API request. Associates a strongly-typed Decodable Response, HTTPMethod, headers, query items, body, and AuthRequirement.",
    code: `struct FetchFeed: Endpoint {
    typealias Response = [FeedItem]
    var path: String { "/feed" }
    var method: HTTPMethod { .get }
}`,
  },
  {
    name: "NetworkConfiguration",
    category: "core",
    type: "Struct",
    signature: "public struct NetworkConfiguration: Sendable",
    summary: "Central configuration holding environment, default headers, TokenStorage, RetryPolicy, SSLPinning, Cache, Concurrency limit, and Logger.",
    code: `var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.retry = .default
config.cache = .memory(policy: .staleWhileRevalidate)
config.sslPinning = .publicKeys(["sha256/..."])`,
  },
  {
    name: "TokenManager",
    category: "auth",
    type: "Actor",
    signature: "public actor TokenManager: TokenManaging",
    summary: "Swift Actor managing single-flight 401 refresh token exchanges, caller queueing, loop guards, and proactive token expiration refresh.",
    code: `let manager = TokenManager(storage: KeychainTokenStorage(service: "app"), refresh: { ... })
let token = try await manager.validToken()`,
  },
  {
    name: "KeychainTokenStorage",
    category: "auth",
    type: "Class",
    signature: "public final class KeychainTokenStorage: TokenStorage, @unchecked Sendable",
    summary: "Production iOS/macOS Keychain storage for TokenPair with device-only kSecAttrAccessibleAfterFirstUnlock protection.",
    code: `let storage = KeychainTokenStorage(service: "com.acme.app", accessibility: .afterFirstUnlockThisDeviceOnly)`,
  },
  {
    name: "AuthorizationCodeFlow",
    category: "oauth",
    type: "Struct",
    signature: "public struct AuthorizationCodeFlow: Sendable",
    summary: "OAuth 2.0 Authorization Code flow with RFC 7636 PKCE. Generates authorization URLs, exchanges codes, and provides tokenManagerRefreshHandler.",
    code: `let flow = AuthorizationCodeFlow(configuration: oauthConfig)
let authURL = flow.authorizationURL(state: state, pkce: pkce)
let tokens = try await flow.exchange(code: code, pkce: pkce)`,
  },
  {
    name: "DiskCacheStore",
    category: "cache",
    type: "Actor",
    signature: "public actor DiskCacheStore: ResponseCacheStore",
    summary: "Disk-backed LRU HTTP response cache. Encrypted at rest with .completeFileProtectionUnlessOpen. Honors ETag, 304, and Cache-Control.",
    code: `config.cache = CacheConfiguration(store: DiskCacheStore(), defaultPolicy: .staleWhileRevalidate, defaultTTL: 300)`,
  },
  {
    name: "FileOfflineStore",
    category: "offline",
    type: "Actor",
    signature: "public actor FileOfflineStore: OfflineRequestStore",
    summary: "Persisted offline request queue. Encrypted at rest; automatically replays queued endpoints FIFO upon network reconnection.",
    code: `config.offlineStore = FileOfflineStore()
for await event in await client.offlineReplayEvents() {
    print("Replayed: \\(event)")
}`,
  },
  {
    name: "RetryPolicy",
    category: "retry",
    type: "Struct",
    signature: "public struct RetryPolicy: Sendable",
    summary: "Configures exponential/constant backoff, full/equal jitter, idempotency safety, and Retry-After server header compliance.",
    code: `config.retry = RetryPolicy(maxAttempts: 3, backoff: .exponential(base: 0.5), jitter: .full, respectRetryAfter: true)`,
  },
  {
    name: "SSLPinningConfiguration",
    category: "security",
    type: "Enum",
    signature: "public enum SSLPinningConfiguration: Sendable",
    summary: "Zero-dependency SSL pinning supporting .certificateResources (.cer/.der), SPKI SHA-256 .publicKeys, and .development discovery mode.",
    code: `config.sslPinning = .publicKeys(["sha256/k2v657xMp4bCWqJaQDZrU3J38RxQL0WPSnguE/9czoq="])`,
  },
  {
    name: "PathNetworkMonitor",
    category: "connectivity",
    type: "Class",
    signature: "public final class PathNetworkMonitor: NetworkMonitor, Sendable",
    summary: "Real-time connectivity monitoring over NWPathMonitor. Provides statusUpdates() and connectionRestored() AsyncStreams.",
    code: `let monitor = PathNetworkMonitor()
for await status in await monitor.statusUpdates() {
    print("Network state: \\(status)")
}`,
  },
  {
    name: "MultipartFormData",
    category: "upload",
    type: "Struct",
    signature: "public struct MultipartFormData: Sendable",
    summary: "RFC 7578 compliant multipart/form-data generator. Streams large binary files directly from disk without blowing memory limits.",
    code: `var form = MultipartFormData()
form.append("Avatar", name: "title")
form.append(photoURL, name: "image")
let result: UploadResult = try await client.upload(UploadEndpoint(), from: .multipart(form)) { event in
    print("Progress: \\(event.fraction ?? 0 * 100)%")
}`,
  },
  {
    name: "PaginatedEndpoint",
    category: "pagination",
    type: "Protocol",
    signature: "public protocol PaginatedEndpoint: Endpoint",
    summary: "Protocol defining cursor or page-number based pagination. Conforms seamlessly with client.paginate() AsyncThrowingStream and collectAll().",
    code: `for try await page in client.paginate(ListUsersEndpoint()) {
    print("Fetched page with \\(page.count) users")
}`,
  },
  {
    name: "NetworkResource",
    category: "swiftui",
    type: "Class / @Observable",
    signature: "@Observable public final class NetworkResource<Value>: @unchecked Sendable",
    summary: "SwiftUI iOS 17+ state holder managing phase (.idle, .loading, .loaded, .failed), value, error, and pull-to-refresh reload().",
    code: `@State private var user = NetworkResource<User>(client: client)
// In SwiftUI: await user.load(GetProfile())`,
  },
  {
    name: "MockNetworkTransport",
    category: "testing",
    type: "Class",
    signature: "public final class MockNetworkTransport: NetworkTransport, @unchecked Sendable",
    summary: "Comprehensive test seam shipping inside the package. Stub JSON models, HTTP status codes, network errors, and MockScenario presets.",
    code: `let mock = MockNetworkTransport().enqueueJSON(User(id: 1, name: "Ada"), status: 200)
let client = NetworkClient(configuration: config, transport: mock)`,
  },
];

export function ApiExplorer() {
  const [category, setCategory] = useState<string>("all");
  const [search, setSearch] = useState<string>("");

  const filtered = API_SYMBOLS.filter((item) => {
    const matchCat = category === "all" || item.category === category;
    const matchSearch =
      search === "" ||
      item.name.toLowerCase().includes(search.toLowerCase()) ||
      item.summary.toLowerCase().includes(search.toLowerCase());
    return matchCat && matchSearch;
  });

  return (
    <section id="api-reference" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-sky-500/10 text-sky-700 dark:text-sky-400 border border-sky-500/20 text-xs font-semibold mb-3 font-mono">
          <BookOpen className="w-3.5 h-3.5" /> TYPE REFERENCE
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Searchable API Reference
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Comprehensive type dictionary for protocols, models, actors, interceptors, cache stores, offline queues, and testing utilities.
        </p>
      </div>

      <div className="flex flex-col md:flex-row items-center justify-between gap-4 mb-8">
        <div className="w-full md:w-96 relative">
          <Search className="w-4 h-4 text-slate-500 absolute left-3.5 top-3.5" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Search classes, protocols, types..."
            className="w-full pl-10 pr-4 py-2.5 rounded-xl bg-white dark:bg-slate-900 border border-slate-300 dark:border-white/10 text-sm text-slate-900 dark:text-slate-200 placeholder-slate-400 focus:border-sky-500 focus:outline-none font-mono shadow-sm"
          />
        </div>

        <div className="flex flex-wrap items-center gap-1.5">
          {["all", "core", "auth", "oauth", "cache", "offline", "retry", "security", "upload", "pagination", "swiftui", "testing"].map((cat) => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-2.5 py-1 rounded-lg text-xs font-semibold cursor-pointer transition-all uppercase ${
                category === cat
                  ? "bg-sky-600 text-white shadow-sm"
                  : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 shadow-sm border border-slate-200 dark:border-transparent"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {filtered.map((item, i) => (
          <div key={i} className="glass-panel p-6 flex flex-col justify-between hover:border-sky-500/50 transition-all duration-300 bg-white/90 dark:bg-slate-900/70 shadow-lg rounded-2xl">
            <div>
              <div className="flex items-center justify-between mb-3">
                <span className="text-xs font-mono px-2.5 py-1 rounded-md bg-sky-500/10 text-sky-700 dark:text-sky-400 border border-sky-500/20 font-bold">
                  {item.type}
                </span>
                <span className="text-xs font-mono text-slate-500 uppercase">{item.category}</span>
              </div>
              <h3 className="text-xl font-bold font-mono text-slate-900 dark:text-white mb-2">{item.name}</h3>
              <p className="text-sm text-slate-600 dark:text-slate-400 mb-4 leading-relaxed">{item.summary}</p>
            </div>
            <div>
              <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 font-mono text-xs text-sky-300 overflow-x-auto mb-3">
                <pre className="whitespace-pre font-mono"><code>{item.signature}</code></pre>
              </div>
              <div className="p-3 rounded-lg bg-slate-950 border border-slate-800 font-mono text-xs text-slate-300 overflow-x-auto">
                <pre className="whitespace-pre font-mono"><code>{item.code}</code></pre>
              </div>
            </div>
          </div>
        ))}
      </div>
    </section>
  );
}
