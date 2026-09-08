"use client";

import React, { useState } from "react";
import { GitCompare, Sparkles, AlertCircle, Check, X, Minus } from "lucide-react";

type LibraryKey = "alamofire" | "moya" | "urlsession" | "combine_async" | "openapi_apollo";

interface ComparisonData {
  title: string;
  tagline: string;
  snkPros: string[];
  otherCons: string[];
  snkCode: string;
  otherCode: string;
  otherLabel: string;
}

const COMPARISONS: Record<LibraryKey, ComparisonData> = {
  alamofire: {
    title: "SwiftNetworkKit vs. Alamofire",
    tagline: "Modern Swift 6 Strict Concurrency vs. Legacy Callback Architecture",
    otherLabel: "Alamofire Tradeoffs",
    snkPros: [
      "Pure Swift 6 Actor-isolated concurrency with 0 compiler data races",
      "Zero external dependencies (pure Apple standard frameworks)",
      "Single-flight 401 token refresh built natively into the actor layer",
      "Built-in SPKI SHA-256 Public Key Pinning with development discovery mode",
      "Automatic Bearer token & password redaction in logs",
      "Persisted offline request queue with automatic FIFO replay on reconnect",
    ],
    otherCons: [
      "Historical codebase originally designed around completion handlers & GCD locks",
      "Token refresh retriers require manual mutex / semaphore synchronizations",
      "Heavier binary footprint with thousands of lines of legacy code",
      "Logging does not redact sensitive Bearer tokens out-of-the-box",
      "No built-in persisted offline request queue or SwiftUI @Observable bindings",
    ],
    snkCode: `// SwiftNetworkKit (Pure Swift 6 & Actor Isolated)
let client = NetworkClient(
    configuration: NetworkConfiguration(
        baseURL: "https://api.acme.com",
        tokenStorage: KeychainTokenStorage(service: "com.acme.app")
    ),
    refresh: { storage in
        try await authService.refreshToken(storage.refreshToken())
    }
)

struct GetFeed: Endpoint {
    typealias Response = [FeedItem]
    var path: String { "/feed" }
    var authentication: AuthRequirement { .required }
}

let feed = try await client.request(GetFeed())`,
    otherCode: `// Alamofire (Requires RequestInterceptor / Lock State Machine)
class OAuthAuthenticator: RequestInterceptor {
    private let lock = NSLock()
    private var isRefreshing = false
    private var requestsToRetry: [(RetryResult) -> Void] = []
    
    func retry(_ request: Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        lock.lock(); defer { lock.unlock() }
        // Complex manual queue management & lock state handling...
    }
}

let session = Session(interceptor: OAuthAuthenticator())
let feed = try await session.request("https://api.acme.com/feed")
    .serializingDecodable([FeedItem].self)
    .value`,
  },
  moya: {
    title: "SwiftNetworkKit vs. Moya",
    tagline: "Direct Swift Protocols vs. Heavy Transitive Dependencies",
    otherLabel: "Moya Tradeoffs",
    snkPros: [
      "Zero external dependencies (Moya pulls in Alamofire and multiple wrappers)",
      "100% Swift 6 compiler compliance with Sendable value guarantees",
      "Lightweight and lightning fast to compile",
      "Built-in single-flight token refresh, jitter retry, offline queue, and metrics sinks",
    ],
    otherCons: [
      "Heavy external dependency graph (Alamofire + Moya + sub-specs)",
      "Enum-based TargetType causes massive monolithic switch statements across app targets",
      "No native actor-isolated single-flight 401 refresh mechanism",
      "Slower compilation and high maintenance baggage",
    ],
    snkCode: `// SwiftNetworkKit (Composable Protocol-per-Endpoint)
struct SubmitOrder: Endpoint {
    typealias Response = OrderReceipt
    var path: String { "/orders" }
    var method: HTTPMethod { .post }
    var body: RequestBody? { .json(currentOrder) }
    var retryPolicy: RetryPolicy? { RetryPolicy(retryNonIdempotent: true) }
    var offlineBehavior: OfflineBehavior { .queue }
}

let receipt = try await client.request(SubmitOrder())`,
    otherCode: `// Moya (Giant Monolithic Enum TargetType)
enum MyAPIService: TargetType {
    case getFeed
    case submitOrder(Order)
    
    var baseURL: URL { URL(string: "https://api.acme.com")! }
    var path: String {
        switch self {
        case .getFeed: return "/feed"
        case .submitOrder: return "/orders"
        }
    }
    // Must write 6 different switch statements across all enum cases!
}`,
  },
  urlsession: {
    title: "SwiftNetworkKit vs. Vanilla URLSession",
    tagline: "Production-Ready Architecture vs. 1,000+ Lines of Boilerplate",
    otherLabel: "URLSession Tradeoffs",
    snkPros: [
      "Eliminates 1,000+ lines of custom boilerplate per iOS application",
      "Actor-isolated TokenManager solves 401 race conditions out-of-the-box",
      "Intelligent exponential backoff with full jitter and Retry-After support",
      "Zero-dependency SPKI SSL pinning without touching raw C-based SecTrust APIs",
      "RFC 7578 multipart disk streaming with byte progress events",
      "Built-in disk caching, offline replay queue, and test doubles",
    ],
    otherCons: [
      "Requires writing your own token refresh lock engine and retry queue from scratch",
      "Manual URLSessionDelegate SSL challenge handling is prone to security bugs",
      "No built-in redaction (developers accidentally log authorization headers)",
      "Writing RFC 7578 multipart form data by hand in memory is tedious and error-prone",
      "No declarative endpoint mapping or structured error mapping",
    ],
    snkCode: `// SwiftNetworkKit (1 declarative statement)
var config = NetworkConfiguration(baseURL: "https://api.acme.com")
config.sslPinning = .publicKeys(["sha256/k2v657x...="])
config.retry = .standard
config.cache = CacheConfiguration(store: DiskCacheStore(), defaultPolicy: .returnCacheDataElseLoad)

let user: User = try await client.request(GetProfile())`,
    otherCode: `// Vanilla URLSession (Dozens of lines of error-prone delegate code)
class PinningDelegate: NSObject, URLSessionDelegate {
    func urlSession(_ session: URLSession, didReceive challenge: URLAuthenticationChallenge,
                    completionHandler: @escaping (URLSession.AuthChallengeDisposition, URLCredential?) -> Void) {
        guard let serverTrust = challenge.protectionSpace.serverTrust else {
            return completionHandler(.cancelAuthenticationChallenge, nil)
        }
        // Manual SecTrustEvaluateWithError, SPKI extraction, DER parsing...
    }
}`,
  },
  combine_async: {
    title: "SwiftNetworkKit vs. Combine / Reactive Pipelines",
    tagline: "Swift 6 Structured Concurrency vs. Legacy Reactive Operators & Memory Leaks",
    otherLabel: "Combine / RxSwift Tradeoffs",
    snkPros: [
      "Built purely on Swift 6 structured concurrency (async/await, Task, AsyncSequence)",
      "Native iOS 17+ @Observable macros with automatic granular SwiftUI view invalidation",
      "Zero AnyCancellable bag management, retain cycle hazards, or memory leaks",
      "Clean linear execution flow with try/catch and actor data-isolation guarantees",
    ],
    otherCons: [
      "Combine publishers lack Swift 6 Strict Concurrency @Sendable cross-isolation safety",
      "Requires managing Set<AnyCancellable> across every view model and coordinator",
      "Complex operator chains (flatMap, retryWhen, shareReplay) obscure error stack traces",
      "Deprecated / unmaintained on visionOS & Linux server-side Swift environments",
    ],
    snkCode: `// SwiftNetworkKit (Swift 6 Observation + AsyncSequence)
@Observable final class ProfileViewModel {
    var state: ResourceState<User> = .idle
    private let client: NetworkClient
    
    func load() async {
        state = .loading
        do {
            let user: User = try await client.request(GetProfile())
            state = .loaded(user)
        } catch {
            state = .error(error)
        }
    }
}`,
    otherCode: `// Combine (Complex Cancellable Bags & Retain Cycles)
class ProfileViewModel: ObservableObject {
    @Published var user: User?
    private var cancellables = Set<AnyCancellable>()
    
    func load() {
        URLSession.shared.dataTaskPublisher(for: url)
            .map(\\ .data)
            .decode(type: User.self, decoder: JSONDecoder())
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { _ in }, receiveValue: { [weak self] in
                self?.user = $0
            })
            .store(in: &cancellables)
    }
}`,
  },
  openapi_apollo: {
    title: "SwiftNetworkKit vs. OpenAPI / Apollo Code-Gen",
    tagline: "Protocol-Oriented Swift Endpoints vs. Brittle Code-Gen Bloat",
    otherLabel: "Code-Gen Tooling Tradeoffs",
    snkPros: [
      "Zero build-phase scripts, code generators, or external CLI toolchain dependencies",
      "First-class Swift protocols tailored specifically to your app domain models",
      "Instant incremental build times (no waiting for schema generation steps)",
      "Full control over encoding, decoding strategies, date formatting, and caching policies",
    ],
    otherCons: [
      "Requires running CLI tools or Xcode build phase scripts on every build",
      "Massive generated boilerplate files inflating repository size and compilation times",
      "Rigid generated types make customizing caching, retry, or security interceptors difficult",
      "Schema mismatches during CI/CD cause sudden project build breakages",
    ],
    snkCode: `// SwiftNetworkKit (100% Native Swift Protocol Endpoint)
struct SearchProducts: Endpoint {
    typealias Response = [Product]
    var path: String { "/products/search" }
    var queryItems: [URLQueryItem]? {
        [URLQueryItem(name: "q", value: query)]
    }
    var cachePolicy: CachePolicy { .returnCacheDataElseLoad }
    let query: String
}

let items = try await client.request(SearchProducts(query: "swift6"))`,
    otherCode: `// OpenAPI / Apollo Code-Gen (Fragile Schema CLI + Generated Files)
// Requires: openapi-generator generate -i schema.yaml -g swift5
// Produces 45+ generated .swift files with rigid generic wrappers:
let request = OpenAPIClientAPI.SearchAPI.searchProducts(
    q: "swift6",
    apiResponseQueue: .main
) { result, error in
    // Generated callback handler...
}`,
  },
};

export function LibraryComparison() {
  const [selectedLib, setSelectedLib] = useState<LibraryKey>("alamofire");
  const data = COMPARISONS[selectedLib];

  return (
    <section id="compare" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 text-xs font-semibold mb-3 font-mono">
          <GitCompare className="w-3.5 h-3.5" /> ECOSYSTEM COMPARISON
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          How SwiftNetworkKit Compares
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          See why modern Swift 6 projects choose SwiftNetworkKit over legacy callback frameworks, reactive overhead, code-gen clutter, or bare URLSession boilerplate.
        </p>
      </div>

      {/* Head to Head Selector */}
      <div className="glass-panel p-6 sm:p-8 mb-16 bg-white/90 dark:bg-slate-900/70 shadow-xl border border-slate-200 dark:border-white/10">
        <div className="flex flex-col lg:flex-row lg:items-center justify-between gap-4 pb-6 mb-6 border-b border-slate-200 dark:border-white/10">
          <div>
            <h3 className="text-2xl font-bold text-slate-900 dark:text-white mb-1">{data.title}</h3>
            <p className="text-sm text-sky-700 dark:text-sky-400 font-mono font-semibold">{data.tagline}</p>
          </div>

          <div className="flex flex-wrap items-center gap-2">
            {[
              { id: "alamofire", label: "vs. Alamofire" },
              { id: "moya", label: "vs. Moya" },
              { id: "urlsession", label: "vs. URLSession" },
              { id: "combine_async", label: "vs. Combine / Rx" },
              { id: "openapi_apollo", label: "vs. OpenAPI / Apollo" },
            ].map((tab) => (
              <button
                key={tab.id}
                onClick={() => setSelectedLib(tab.id as LibraryKey)}
                className={`px-3.5 py-2 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                  selectedLib === tab.id
                    ? "bg-sky-600 text-white shadow-md shadow-sky-600/30"
                    : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 shadow-sm border border-slate-200 dark:border-transparent"
                }`}
              >
                {tab.label}
              </button>
            ))}
          </div>
        </div>

        {/* Pros & Cons */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-8 mb-8">
          <div className="p-5 rounded-2xl bg-emerald-50/70 dark:bg-slate-950/60 border border-emerald-500/30 shadow-sm">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-lg bg-emerald-500/20 flex items-center justify-center text-emerald-600 dark:text-emerald-400">
                <Sparkles className="w-4 h-4" />
              </div>
              <h4 className="font-bold text-sm text-emerald-800 dark:text-emerald-400 font-mono uppercase tracking-wide">
                SwiftNetworkKit Advantages
              </h4>
            </div>
            <ul className="space-y-2.5">
              {data.snkPros.map((p, i) => (
                <li key={i} className="flex items-start gap-2 text-xs text-slate-800 dark:text-slate-300 font-medium">
                  <Check className="w-4 h-4 text-emerald-600 dark:text-emerald-400 shrink-0 mt-0.5" />
                  <span>{p}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="p-5 rounded-2xl bg-amber-50/70 dark:bg-slate-950/60 border border-amber-500/30 shadow-sm">
            <div className="flex items-center gap-2 mb-4">
              <div className="w-7 h-7 rounded-lg bg-amber-500/20 flex items-center justify-center text-amber-600 dark:text-amber-400">
                <AlertCircle className="w-4 h-4" />
              </div>
              <h4 className="font-bold text-sm text-amber-800 dark:text-amber-400 font-mono uppercase tracking-wide">
                {data.otherLabel}
              </h4>
            </div>
            <ul className="space-y-2.5">
              {data.otherCons.map((c, i) => (
                <li key={i} className="flex items-start gap-2 text-xs text-slate-800 dark:text-slate-400 font-medium">
                  <AlertCircle className="w-4 h-4 text-amber-600 dark:text-amber-400 shrink-0 mt-0.5" />
                  <span>{c}</span>
                </li>
              ))}
            </ul>
          </div>
        </div>

        {/* Code Diffs */}
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs overflow-x-auto text-sky-300 shadow-md">
            <div className="text-emerald-400 font-semibold mb-2 text-[11px] uppercase tracking-wider">
              SwiftNetworkKit (Modern Swift 6)
            </div>
            <pre className="whitespace-pre font-mono leading-relaxed"><code>{data.snkCode}</code></pre>
          </div>

          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs overflow-x-auto text-slate-300 shadow-md">
            <div className="text-amber-400 font-semibold mb-2 text-[11px] uppercase tracking-wider">
              Alternative Implementation
            </div>
            <pre className="whitespace-pre font-mono leading-relaxed"><code>{data.otherCode}</code></pre>
          </div>
        </div>
      </div>

      {/* Feature Matrix Table */}
      <div className="table-container shadow-2xl bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-white/10">
        <table className="compare-table">
          <thead>
            <tr>
              <th className="w-1/3">Capability / Architecture</th>
              <th className="compare-highlight-col text-orange-600 dark:text-orange-400 font-bold">SwiftNetworkKit</th>
              <th>Alamofire</th>
              <th>Moya</th>
              <th>Vanilla URLSession</th>
            </tr>
          </thead>
          <tbody>
            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Swift 6 Strict Concurrency</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">13 isolated actors, 0 data races, Sendable guarantees</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Native Swift 6
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Partial (v5.9+)</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">Legacy Rx roots</td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Manual sync</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>External Dependencies</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Zero third-party code in compiled binary</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> 0 Dependencies
                </span>
              </td>
              <td className="text-emerald-700 dark:text-emerald-400 text-xs font-mono font-semibold">0 Dependencies</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">Multiple packages</td>
              <td className="text-emerald-700 dark:text-emerald-400 text-xs font-mono font-semibold">0 (Built-in)</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Single-Flight 401 Token Refresh</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Actor-isolated queueing without race conditions</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Built-in Actor
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Manual Retrier</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">Not built-in</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">DIY boilerplate</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>SPKI Public Key SHA-256 Pinning</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Survives certificate renewal, zero extra libs</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Native SPKI
                </span>
              </td>
              <td className="text-emerald-700 dark:text-emerald-400 text-xs font-mono font-semibold">ServerTrust</td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Via Alamofire</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">Complex C-APIs</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>RFC 7578 Multipart Disk Streaming</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">500MB+ file uploads directly from disk without OOM</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Zero-Copy Disk Stream
                </span>
              </td>
              <td className="text-emerald-700 dark:text-emerald-400 text-xs font-mono font-semibold">MultipartFormData</td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Basic Wrappers</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">Manual Byte Buffers</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Persisted Offline Request Queue</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Encrypted FIFO spool with automatic reconnect drain</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Built-in Spool Actor
                </span>
              </td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Two-Tier Cache &amp; Stale-While-Revalidate</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Memory + DiskCacheStore with SHA-256 &amp; ETag 304</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> L1 + L2 with SWR
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Basic URLCache</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">URLCache only</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Jittered Retry &amp; Rate-Limiting</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Full &amp; equal jitter, Retry-After header parsing</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Full Jitter + Headers
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Basic Backoff</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">External / Plugin</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>SwiftUI @Observable &amp; AsyncSequence</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">NetworkResource state container for iOS 17+ Observation</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Native NetworkResource
                </span>
              </td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">Combine only</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Zero-Overhead In-Memory Metrics</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Microsecond P50/P90/P95 latency tracking &amp; error histograms</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Native NetworkMetrics
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">EventMonitor</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Privacy Redacting Logger</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Automatic secret, token &amp; auth header masking</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> Automatic Redaction
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Raw Logs</td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">Raw Logs</td>
              <td className="text-rose-700 dark:text-rose-400 text-xs font-mono font-semibold">None</td>
            </tr>

            <tr>
              <td className="font-semibold text-slate-900 dark:text-white">
                <div>Mock Transport &amp; Deterministic Tests</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Protocol-based mock transport with 0 network calls</div>
              </td>
              <td className="compare-highlight-col">
                <span className="text-emerald-600 dark:text-emerald-400 text-xs font-bold font-mono flex items-center gap-1">
                  <Check className="w-3.5 h-3.5" /> MockTransport Protocol
                </span>
              </td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">URLProtocol Stubbing</td>
              <td className="text-emerald-700 dark:text-emerald-400 text-xs font-mono font-semibold">SampleData (Enum)</td>
              <td className="text-amber-700 dark:text-amber-400 text-xs font-mono font-semibold">URLProtocol subclass</td>
            </tr>
          </tbody>
        </table>
      </div>
    </section>
  );
}
