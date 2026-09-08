"use client";

import React, { useState } from "react";
import { GitCompare, Sparkles, AlertCircle, Check } from "lucide-react";

type LibraryKey = "alamofire" | "moya" | "urlsession";

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
      "Pure Swift 6 Actor-isolated concurrency with 0 data races",
      "Zero external dependencies (pure Apple standard frameworks)",
      "Single-flight 401 token refresh built into the actor layer",
      "Built-in SPKI SHA-256 Public Key Pinning with development discovery mode",
      "Automatic Bearer token & password redaction in logs",
      "Native AsyncStream reachability monitoring",
    ],
    otherCons: [
      "Historical codebase originally designed around completion handlers & GCD locks",
      "Token refresh retriers require manual mutex / semaphore synchronizations",
      "Heavier binary footprint with thousands of lines of legacy code",
      "Logging does not redact sensitive Bearer tokens out-of-the-box",
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
      "100% Swift 6 compiler compliance with Sendable guarantees",
      "Lightweight and lightning fast to compile",
      "Built-in single-flight token refresh, jitter retry, and metrics sinks",
    ],
    otherCons: [
      "Heavy external dependency graph (Alamofire + Moya + sub-specs)",
      "Enum-based TargetType causes massive monolithic switch statements",
      "No native actor-isolated single-flight 401 refresh mechanism",
      "Slower compilation and maintenance baggage",
    ],
    snkCode: `// SwiftNetworkKit (Composable Protocol-per-Endpoint)
struct SubmitOrder: Endpoint {
    typealias Response = OrderReceipt
    var path: String { "/orders" }
    var method: HTTPMethod { .post }
    var body: RequestBody? { .json(currentOrder) }
    var retryPolicy: RetryPolicy? { RetryPolicy(retryNonIdempotent: true) }
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
    ],
    otherCons: [
      "Requires writing your own token refresh lock engine and retry queue from scratch",
      "Manual URLSessionDelegate SSL challenge handling is prone to security bugs",
      "No built-in redaction (developers accidentally log authorization headers)",
      "Writing RFC 7578 multipart form data by hand in memory is tedious and error-prone",
    ],
    snkCode: `// SwiftNetworkKit (1 declarative statement)
var config = NetworkConfiguration(baseURL: "https://api.acme.com")
config.sslPinning = .publicKeys(["sha256/k2v657x...="])
config.retry = .standard

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
          See why modern Swift 6 projects choose SwiftNetworkKit over heavy legacy frameworks or bare URLSession boilerplate.
        </p>
      </div>

      {/* Head to Head Selector */}
      <div className="glass-panel p-6 sm:p-8 mb-16 bg-white/90 dark:bg-slate-900/70 shadow-xl border border-slate-200 dark:border-white/10">
        <div className="flex flex-wrap items-center justify-between gap-4 pb-6 mb-6 border-b border-slate-200 dark:border-white/10">
          <div>
            <h3 className="text-2xl font-bold text-slate-900 dark:text-white mb-1">{data.title}</h3>
            <p className="text-sm text-sky-700 dark:text-sky-400 font-mono font-semibold">{data.tagline}</p>
          </div>

          <div className="flex items-center gap-2">
            <button
              onClick={() => setSelectedLib("alamofire")}
              className={`px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                selectedLib === "alamofire"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-600/30"
                  : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 shadow-sm border border-slate-200 dark:border-transparent"
              }`}
            >
              vs. Alamofire
            </button>
            <button
              onClick={() => setSelectedLib("moya")}
              className={`px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                selectedLib === "moya"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-600/30"
                  : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 shadow-sm border border-slate-200 dark:border-transparent"
              }`}
            >
              vs. Moya
            </button>
            <button
              onClick={() => setSelectedLib("urlsession")}
              className={`px-4 py-2 rounded-xl text-xs font-semibold cursor-pointer transition-all ${
                selectedLib === "urlsession"
                  ? "bg-sky-600 text-white shadow-md shadow-sky-600/30"
                  : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 shadow-sm border border-slate-200 dark:border-transparent"
              }`}
            >
              vs. Vanilla URLSession
            </button>
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
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Actor boundaries, 0 data races, Sendable</div>
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
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Zero third-party code in binary</div>
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
                <div>Jittered Retry & Rate-Limiting</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Full & equal jitter, Retry-After header parsing</div>
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
                <div>Privacy Redacting Logger</div>
                <div className="text-xs text-slate-500 dark:text-slate-400 font-normal">Automatic secret, token & auth header masking</div>
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
          </tbody>
        </table>
      </div>
    </section>
  );
}
