"use client";

import React, { useState } from "react";
import { BookOpen, Search } from "lucide-react";

interface ApiItem {
  name: string;
  category: "core" | "auth" | "retry" | "security" | "connectivity" | "upload" | "testing";
  type: string;
  signature: string;
  summary: string;
  code: string;
}

const API_SYMBOLS: ApiItem[] = [
  {
    name: "NetworkClient",
    category: "core",
    type: "Class / Actor-safe",
    signature: "public final class NetworkClient: Sendable",
    summary: "The main networking engine. Manages request dispatching, URLSession lifecycle, token refresh loops, and metrics sinks.",
    code: `let client = NetworkClient(configuration: config, refresh: { ... })
let user: User = try await client.request(GetProfile())`,
  },
  {
    name: "Endpoint",
    category: "core",
    type: "Protocol",
    signature: "public protocol Endpoint: Sendable",
    summary: "Protocol declaring an API request. Associates a strongly-typed Decodable Response, HTTPMethod, headers, and AuthRequirement.",
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
    summary: "Central configuration holding baseURL, default headers, TokenStorage, RetryPolicy, SSLPinning, Interceptors, and Metrics.",
    code: `var config = NetworkConfiguration(baseURL: "https://api.example.com")
config.retry = .standard
config.sslPinning = .publicKeys(["sha256/..."])`,
  },
  {
    name: "TokenManager",
    category: "auth",
    type: "Actor",
    signature: "public actor TokenManager",
    summary: "Swift Actor managing single-flight 401 refresh token exchanges, caller queueing, loop guards, and Keychain accessibility.",
    code: `let manager = TokenManager(storage: KeychainTokenStorage(service: "app"), refresh: { ... })
let token = try await manager.validToken()`,
  },
  {
    name: "KeychainTokenStorage",
    category: "auth",
    type: "Class",
    signature: "public final class KeychainTokenStorage: TokenStorage, @unchecked Sendable",
    summary: "Production-ready iOS/macOS Keychain storage for access and refresh token pairs with customizable kSecAttrAccessible levels.",
    code: `let storage = KeychainTokenStorage(service: "com.acme.app", accessibility: .afterFirstUnlock)`,
  },
  {
    name: "RetryPolicy",
    category: "retry",
    type: "Struct",
    signature: "public struct RetryPolicy: Sendable",
    summary: "Configures exponential/constant backoff, full/equal jitter, max attempts, and Retry-After server header compliance.",
    code: `let policy = RetryPolicy(maxAttempts: 3, backoff: .exponential(initial: 0.5), jitter: .full)`,
  },
  {
    name: "SSLPinningConfiguration",
    category: "security",
    type: "Enum",
    signature: "public enum SSLPinningConfiguration: Sendable",
    summary: "Zero-dependency SSL pinning supporting .certificateResources, SPKI SHA-256 .publicKeys, and .development discovery mode.",
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
    name: "MockNetworkTransport",
    category: "testing",
    type: "Testing Utilities",
    signature: "public final class MockNetworkTransport: NetworkTransport, @unchecked Sendable",
    summary: "Comprehensive testing kit. Mock responses, stub HTTP status codes, simulate network errors, and control time with TestClock.",
    code: `let mock = MockNetworkTransport()
mock.register(status: 200, json: "{\\"id\\": 1, \\"name\\": \\"Alice\\"}")
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
          Comprehensive type dictionary for protocols, models, actors, interceptors, and testing utilities.
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

        <div className="flex flex-wrap items-center gap-2">
          {["all", "core", "auth", "retry", "security", "testing"].map((cat) => (
            <button
              key={cat}
              onClick={() => setCategory(cat)}
              className={`px-3 py-1.5 rounded-lg text-xs font-semibold cursor-pointer transition-all uppercase ${
                category === cat
                  ? "bg-sky-600 text-white"
                  : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 shadow-sm"
              }`}
            >
              {cat}
            </button>
          ))}
        </div>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
        {filtered.map((item, i) => (
          <div key={i} className="glass-panel p-6 flex flex-col justify-between hover:border-sky-500/50 transition-all duration-300 bg-white/90 dark:bg-slate-900/70 shadow-lg">
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
