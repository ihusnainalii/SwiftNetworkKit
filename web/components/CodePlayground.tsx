"use client";

import React, { useState } from "react";
import {
  Cpu,
  Send,
  SlidersHorizontal,
  Copy,
  Check,
  Globe,
  Code2,
  FileJson,
  Sparkles,
  Layers,
  Terminal,
  AlertCircle,
  Plus,
  Trash2,
  Shield,
  HardDrive,
  Database
} from "lucide-react";

interface HeaderItem {
  key: string;
  value: string;
  enabled: boolean;
}

const PRESET_ENDPOINTS = [
  {
    name: "GitHub Octocat User",
    url: "https://api.github.com/users/octocat",
    method: "GET",
    headers: [{ key: "Accept", value: "application/vnd.github.v3+json", enabled: true }],
    body: "",
    modelName: "GitHubUser"
  },
  {
    name: "JSONPlaceholder Post",
    url: "https://jsonplaceholder.typicode.com/posts/1",
    method: "GET",
    headers: [{ key: "Accept", value: "application/json", enabled: true }],
    body: "",
    modelName: "PostResponse"
  },
  {
    name: "DummyJSON Product",
    url: "https://dummyjson.com/products/1",
    method: "GET",
    headers: [{ key: "Accept", value: "application/json", enabled: true }],
    body: "",
    modelName: "ProductDetail"
  },
  {
    name: "CoinGecko Crypto Rates",
    url: "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin,ethereum&vs_currencies=usd",
    method: "GET",
    headers: [{ key: "Accept", value: "application/json", enabled: true }],
    body: "",
    modelName: "CryptoPriceSnapshot"
  },
  {
    name: "HTTPBin Echo POST",
    url: "https://httpbin.org/post",
    method: "POST",
    headers: [
      { key: "Content-Type", value: "application/json", enabled: true },
      { key: "Accept", value: "application/json", enabled: true }
    ],
    body: JSON.stringify({ name: "Husnain", package: "SwiftNetworkKit", version: "0.1.0" }, null, 2),
    modelName: "EchoPayloadResponse"
  }
];

// Helper to convert JSON keys to Swift camelCase
function toCamelCase(str: string): string {
  return str.replace(/([-_][a-z])/ig, ($1) => {
    return $1.toUpperCase()
      .replace('-', '')
      .replace('_', '');
  });
}

// Helper to infer Swift Type from JS value
function inferSwiftType(val: any, propName: string): string {
  if (val === null || val === undefined) return "String?";
  if (typeof val === "boolean") return "Bool";
  if (typeof val === "number") {
    return Number.isInteger(val) ? "Int" : "Double";
  }
  if (typeof val === "string") {
    if (val.match(/^https?:\/\//)) return "URL?";
    if (val.match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)) return "Date?";
    return "String";
  }
  if (Array.isArray(val)) {
    if (val.length === 0) return "[String]";
    const innerType = inferSwiftType(val[0], propName);
    return `[${innerType}]`;
  }
  if (typeof val === "object") {
    const capitalized = propName.charAt(0).toUpperCase() + propName.slice(1);
    return capitalized;
  }
  return "String";
}

// Generate Swift struct definition from JSON
function generateSwiftStructs(json: any, rootName = "APIResponse"): string {
  if (!json || typeof json !== "object" || Array.isArray(json)) {
    return `public struct ${rootName}: Codable, Sendable {\n    // Single value or array response\n    public let value: String\n}`;
  }

  const nestedStructs: string[] = [];
  const properties: string[] = [];

  for (const [key, value] of Object.entries(json)) {
    const swiftPropName = toCamelCase(key);
    const swiftType = inferSwiftType(value, swiftPropName);

    if (typeof value === "object" && value !== null && !Array.isArray(value)) {
      const nestedName = swiftPropName.charAt(0).toUpperCase() + swiftPropName.slice(1);
      nestedStructs.push(generateSwiftStructs(value, nestedName));
    }

    properties.push(`    public let ${swiftPropName}: ${swiftType}`);
  }

  const mainStruct = `public struct ${rootName}: Codable, Sendable {\n${properties.slice(0, 15).join("\n")}${properties.length > 15 ? "\n    // ... more fields" : ""}\n}`;
  return [mainStruct, ...nestedStructs].join("\n\n");
}

export function CodePlayground() {
  const [url, setUrl] = useState("https://api.github.com/users/octocat");
  const [method, setMethod] = useState<"GET" | "POST" | "PUT" | "DELETE" | "PATCH">("GET");
  const [headers, setHeaders] = useState<HeaderItem[]>([
    { key: "Accept", value: "application/vnd.github.v3+json", enabled: true }
  ]);
  const [reqBody, setReqBody] = useState("");
  const [modelName, setModelName] = useState("GitHubUser");

  // SwiftNetworkKit Configuration options
  const [auth, setAuth] = useState<"bearer" | "apiKey" | "basic" | "none">("none");
  const [retry, setRetry] = useState<"standard" | "aggressive" | "none">("standard");
  const [ssl, setSsl] = useState<"spki" | "disabled">("spki");
  const [cache, setCache] = useState<"returnCacheDataElseLoad" | "reloadRevalidating" | "none">("none");
  const [offline, setOffline] = useState<"fail" | "queue">("fail");
  const [logging, setLogging] = useState<"verbose" | "basic" | "none">("verbose");

  // Output tabs
  const [activeTab, setActiveTab] = useState<"all" | "endpoint" | "model" | "client" | "call">("all");
  const [copied, setCopied] = useState(false);

  // Live Request Execution State
  const [isLoading, setIsLoading] = useState(false);
  const [responseStatus, setResponseStatus] = useState<number | null>(null);
  const [responseStatusText, setResponseStatusText] = useState("");
  const [responseLatency, setResponseLatency] = useState<number | null>(null);
  const [responseHeaders, setResponseHeaders] = useState<Record<string, string>>({});
  const [responseJson, setResponseJson] = useState<any>(null);
  const [responseError, setResponseError] = useState<string | null>(null);

  const applyPreset = (preset: typeof PRESET_ENDPOINTS[0]) => {
    setUrl(preset.url);
    setMethod(preset.method as any);
    setHeaders(preset.headers);
    setReqBody(preset.body);
    setModelName(preset.modelName);
  };

  const addHeader = () => {
    setHeaders([...headers, { key: "", value: "", enabled: true }]);
  };

  const removeHeader = (idx: number) => {
    setHeaders(headers.filter((_, i) => i !== idx));
  };

  const updateHeader = (idx: number, field: keyof HeaderItem, val: any) => {
    const updated = [...headers];
    updated[idx] = { ...updated[idx], [field]: val };
    setHeaders(updated);
  };

  const handleSendLiveRequest = async () => {
    if (!url.trim()) return;
    setIsLoading(true);
    setResponseError(null);
    setResponseStatus(null);
    setResponseJson(null);

    const startTime = performance.now();

    try {
      const headerObj: Record<string, string> = {};
      headers.filter((h) => h.enabled && h.key.trim()).forEach((h) => {
        headerObj[h.key.trim()] = h.value.trim();
      });

      const options: RequestInit = {
        method,
        headers: headerObj
      };

      if (["POST", "PUT", "PATCH"].includes(method) && reqBody.trim()) {
        options.body = reqBody;
      }

      const res = await fetch(url, options);
      const latency = Math.round(performance.now() - startTime);
      setResponseLatency(latency);
      setResponseStatus(res.status);
      setResponseStatusText(res.statusText || "OK");

      const resHeaders: Record<string, string> = {};
      res.headers.forEach((v, k) => {
        resHeaders[k] = v;
      });
      setResponseHeaders(resHeaders);

      const text = await res.text();
      try {
        const parsed = JSON.parse(text);
        setResponseJson(parsed);
      } catch {
        setResponseJson({ raw_response: text.slice(0, 500) });
      }
    } catch (err: any) {
      const latency = Math.round(performance.now() - startTime);
      setResponseLatency(latency);
      setResponseError(
        err.message || "Failed to fetch. This may be due to CORS on third-party servers, but SwiftNetworkKit executes natively on iOS/macOS with zero CORS limitations."
      );
    } finally {
      setIsLoading(false);
    }
  };

  // URL Parser for Swift Endpoint
  let parsedUrl: URL | null = null;
  let origin = "https://api.example.com";
  let pathname = "/v1/resource";
  let searchParams: [string, string][] = [];

  try {
    parsedUrl = new URL(url);
    origin = parsedUrl.origin;
    pathname = parsedUrl.pathname;
    searchParams = Array.from(parsedUrl.searchParams.entries());
  } catch {
    // fallback
  }

  // Generate Swift Code
  const endpointSwift = `import SwiftNetworkKit
import Foundation

// 1. Type-Safe Endpoint Definition
public struct ${modelName}Endpoint: Endpoint {
    public typealias Response = ${modelName}
    
    public var path: String {
        "${pathname}"
    }
    
    public var method: HTTPMethod {
        .${method.toLowerCase()}
    }
    
    public var authentication: AuthRequirement {
        .${auth === "none" ? "none" : "required"}
    }
${
  cache !== "none"
    ? `
    public var cachePolicy: CachePolicy? {
        .${cache}
    }`
    : ""
}${
  offline === "queue"
    ? `
    public var offlineBehavior: OfflineBehavior {
        .queue
    }`
    : ""
}${
  headers.filter((h) => h.enabled && h.key.trim()).length > 0
    ? `
    public var headers: HTTPHeaders {
        [
${headers
  .filter((h) => h.enabled && h.key.trim())
  .map((h) => `            "${h.key}": "${h.value}"`)
  .join(",\n")}
        ]
    }`
    : ""
}${
  searchParams.length > 0
    ? `
    public var queryParameters: QueryParameters? {
        [
${searchParams.map(([k, v]) => `            "${k}": "${v}"`).join(",\n")}
        ]
    }`
    : ""
}${
  ["POST", "PUT", "PATCH"].includes(method) && reqBody.trim()
    ? `
    public var body: RequestBody? {
        .json("""
${reqBody}
""".data(using: .utf8)!)
    }`
    : ""
}
}`;

  const modelSwift = generateSwiftStructs(
    responseJson || {
      id: 1,
      name: "Sample Object",
      status: "active",
      created_at: "2026-03-08T12:00:00Z"
    },
    modelName
  );

  const clientSwift = `import SwiftNetworkKit

// 2. Initialize NetworkClient
var config = NetworkConfiguration(
    baseURL: URL(string: "${origin}")!,
    defaultHeaders: ["User-Agent": "MyiOSApp/1.0"]
)

${
  auth === "bearer"
    ? `config.tokenStorage = KeychainTokenStorage(service: "com.myapp.auth")`
    : auth === "apiKey"
    ? `config.defaultHeaders["X-API-Key"] = "sk_live_sample"`
    : `// Public endpoint without auth`
}
${
  retry === "standard"
    ? `config.retry = .standard // Exponential backoff + full jitter + Retry-After`
    : retry === "aggressive"
    ? `config.retry = RetryPolicy(maxRetries: 5, backoff: .exponential(initialDelay: 0.5, maxDelay: 10.0, jitter: .full))`
    : `config.retry = .none`
}
${
  cache !== "none"
    ? `config.cache = CacheConfiguration(store: DiskCacheStore(), defaultPolicy: .${cache})`
    : `// Caching disabled`
}
${
  offline === "queue"
    ? `config.offlineStore = FileOfflineStore()`
    : `// Offline queueing disabled`
}
${
  ssl === "spki"
    ? `// SPKI SHA-256 Public Key Pinning (Renewal-safe)
config.sslPinning = SSLPinningConfiguration(
    pinnedHashes: ["${parsedUrl?.host || "api.example.com"}": ["sha256/9kE7yZ6W+V2r0x7G3h5...="]]
)`
    : `// SSL Pinning disabled`
}
config.logger = RedactingLogger(rules: RedactionRule.standardRules, logLevel: .${logging})

let client = NetworkClient(configuration: config)`;

  const callSwift = `// 3. Modern Swift 6 Async/Await Execution
do {
    let endpoint = ${modelName}Endpoint()
    let result: ${modelName} = try await client.request(endpoint)
    print("Received typed response: \\(result)")
} catch let error as NetworkError {
    switch error {
    case .unauthorized(let reason):
        print("Unauthorized: \\(reason ?? "Token expired")")
    case .sslPinningFailed(let host):
        print("Security warning: SSL pin mismatch on \\(host)")
    case .httpError(let statusCode, _, let context):
        print("HTTP Error \\(statusCode) on \\(context.requestURL)")
    case .offline:
        print("Device is offline")
    default:
        print("Network request failed: \\(error.localizedDescription)")
    }
}`;

  const fullSwiftCode = `// ==========================================
// SwiftNetworkKit Swift 6 Generated Implementation
// Package: https://github.com/ihusnainalii/SwiftNetworkKit
// ==========================================

${endpointSwift}

// --- Decodable Response Model ---
${modelSwift}

// --- Client Configuration ---
${clientSwift}

// --- Call Execution ---
${callSwift}`;

  const getActiveCode = () => {
    if (activeTab === "all") return fullSwiftCode;
    if (activeTab === "endpoint") return endpointSwift;
    if (activeTab === "model") return modelSwift;
    if (activeTab === "client") return clientSwift;
    return callSwift;
  };

  const copyCode = () => {
    navigator.clipboard.writeText(getActiveCode());
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="playground" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      {/* Header */}
      <div className="text-center max-w-3xl mx-auto mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 text-xs font-semibold mb-3 font-mono">
          <Cpu className="w-3.5 h-3.5" /> INTERACTIVE URL PLAYGROUND
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Real URL Request Playground & Code Generator
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Type any live REST API URL, execute the real HTTP request directly, and get instant, type-safe **Swift 6 `Endpoint`** and **`Codable` models** tailored for the `SwiftNetworkKit` SPM package.
        </p>
      </div>

      {/* Preset Buttons */}
      <div className="flex flex-wrap items-center justify-center gap-2 mb-8">
        <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400 flex items-center gap-1 mr-2">
          <Sparkles className="w-3.5 h-3.5 text-sky-500" /> Presets:
        </span>
        {PRESET_ENDPOINTS.map((preset) => (
          <button
            key={preset.name}
            onClick={() => applyPreset(preset)}
            className="px-3 py-1.5 rounded-xl text-xs font-medium glass-panel border border-slate-200 dark:border-slate-800 bg-white dark:bg-slate-900/60 hover:border-sky-500 text-slate-700 dark:text-slate-300 transition-all cursor-pointer shadow-sm"
          >
            {preset.name}
          </button>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-start">
        {/* Left Column: Real Request Builder (5 cols) */}
        <div className="lg:col-span-5 space-y-6">
          <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xl space-y-5">
            <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
              <span className="flex items-center gap-2">
                <Globe className="w-4 h-4 text-sky-500" />
                Live HTTP Request Builder
              </span>
              <span className="text-[11px] font-mono px-2 py-0.5 rounded bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20">
                Interactive
              </span>
            </h3>

            {/* URL & Method Input */}
            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                Target API Endpoint URL
              </label>
              <div className="flex gap-2">
                <select
                  value={method}
                  onChange={(e) => setMethod(e.target.value as any)}
                  className="bg-slate-100 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-xl px-2.5 py-2 text-xs font-bold font-mono text-sky-600 dark:text-sky-400 focus:outline-none"
                >
                  <option value="GET">GET</option>
                  <option value="POST">POST</option>
                  <option value="PUT">PUT</option>
                  <option value="DELETE">DELETE</option>
                  <option value="PATCH">PATCH</option>
                </select>

                <input
                  type="text"
                  value={url}
                  onChange={(e) => setUrl(e.target.value)}
                  placeholder="https://api.example.com/v1/resource"
                  className="flex-1 bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-xl px-3 py-2 text-xs font-mono text-slate-900 dark:text-slate-200 focus:border-sky-500 focus:outline-none"
                />
              </div>
            </div>

            {/* Swift Model Struct Name */}
            <div>
              <label className="block text-xs font-mono font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                Swift Struct Name
              </label>
              <input
                type="text"
                value={modelName}
                onChange={(e) => setModelName(e.target.value)}
                placeholder="UserProfile"
                className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-xl px-3 py-2 text-xs font-mono text-slate-900 dark:text-slate-200 focus:border-sky-500 focus:outline-none"
              />
            </div>

            {/* HTTP Headers */}
            <div>
              <div className="flex items-center justify-between mb-2">
                <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300">
                  HTTP Headers ({headers.length})
                </label>
                <button
                  onClick={addHeader}
                  className="text-[11px] font-mono text-sky-600 dark:text-sky-400 hover:underline flex items-center gap-1 cursor-pointer"
                >
                  <Plus className="w-3 h-3" /> Add Header
                </button>
              </div>

              <div className="space-y-2 max-h-36 overflow-y-auto pr-1">
                {headers.map((h, i) => (
                  <div key={i} className="flex items-center gap-2">
                    <input
                      type="checkbox"
                      checked={h.enabled}
                      onChange={(e) => updateHeader(i, "enabled", e.target.checked)}
                      className="rounded accent-sky-500"
                    />
                    <input
                      type="text"
                      placeholder="Header Name"
                      value={h.key}
                      onChange={(e) => updateHeader(i, "key", e.target.value)}
                      className="flex-1 bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-lg px-2 py-1 text-xs font-mono text-slate-900 dark:text-slate-200"
                    />
                    <input
                      type="text"
                      placeholder="Value"
                      value={h.value}
                      onChange={(e) => updateHeader(i, "value", e.target.value)}
                      className="flex-1 bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-lg px-2 py-1 text-xs font-mono text-slate-900 dark:text-slate-200"
                    />
                    <button
                      onClick={() => removeHeader(i)}
                      className="text-slate-400 hover:text-rose-500 p-1 cursor-pointer"
                    >
                      <Trash2 className="w-3.5 h-3.5" />
                    </button>
                  </div>
                ))}
              </div>
            </div>

            {/* Request Body (For POST / PUT / PATCH) */}
            {["POST", "PUT", "PATCH"].includes(method) && (
              <div>
                <label className="block text-xs font-mono font-bold text-slate-700 dark:text-slate-300 mb-1.5">
                  Request Body (JSON)
                </label>
                <textarea
                  value={reqBody}
                  onChange={(e) => setReqBody(e.target.value)}
                  rows={3}
                  placeholder='{"name": "test"}'
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-xl p-2.5 text-xs font-mono text-slate-900 dark:text-slate-200 focus:border-sky-500 focus:outline-none"
                />
              </div>
            )}

            {/* SPM Package Config Toggles */}
            <div className="pt-3 border-t border-slate-200 dark:border-slate-800 grid grid-cols-2 gap-3 text-xs">
              <div>
                <label className="block font-mono font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Auth Strategy
                </label>
                <select
                  value={auth}
                  onChange={(e) => setAuth(e.target.value as any)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-lg px-2 py-1.5 font-mono text-slate-800 dark:text-slate-200"
                >
                  <option value="none">Public (.none)</option>
                  <option value="bearer">Bearer (Keychain)</option>
                  <option value="apiKey">API Key Header</option>
                </select>
              </div>

              <div>
                <label className="block font-mono font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Retry Policy
                </label>
                <select
                  value={retry}
                  onChange={(e) => setRetry(e.target.value as any)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-lg px-2 py-1.5 font-mono text-slate-800 dark:text-slate-200"
                >
                  <option value="standard">Exponential + Jitter</option>
                  <option value="aggressive">Aggressive (5x)</option>
                  <option value="none">Disabled (.none)</option>
                </select>
              </div>

              <div>
                <label className="block font-mono font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Cache Strategy
                </label>
                <select
                  value={cache}
                  onChange={(e) => setCache(e.target.value as any)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-lg px-2 py-1.5 font-mono text-slate-800 dark:text-slate-200"
                >
                  <option value="none">None (Live Hop)</option>
                  <option value="returnCacheDataElseLoad">Cache Else Load</option>
                  <option value="reloadRevalidating">Revalidate Cache</option>
                </select>
              </div>

              <div>
                <label className="block font-mono font-bold text-slate-700 dark:text-slate-300 mb-1">
                  Offline Behavior
                </label>
                <select
                  value={offline}
                  onChange={(e) => setOffline(e.target.value as any)}
                  className="w-full bg-slate-50 dark:bg-slate-950 border border-slate-300 dark:border-slate-800 rounded-lg px-2 py-1.5 font-mono text-slate-800 dark:text-slate-200"
                >
                  <option value="fail">Fail Fast (.fail)</option>
                  <option value="queue">Persist & Replay (.queue)</option>
                </select>
              </div>
            </div>

            {/* Send Live Request Button */}
            <button
              onClick={handleSendLiveRequest}
              disabled={isLoading}
              className="w-full py-2.5 rounded-xl bg-gradient-to-r from-sky-500 to-blue-600 hover:from-sky-400 hover:to-blue-500 text-white font-bold text-xs flex items-center justify-center gap-2 transition-all shadow-lg shadow-sky-500/25 cursor-pointer disabled:opacity-50"
            >
              {isLoading ? (
                <>
                  <div className="w-3.5 h-3.5 border-2 border-white/30 border-t-white rounded-full animate-spin" />
                  <span>Dispatching HTTP Request...</span>
                </>
              ) : (
                <>
                  <Send className="w-3.5 h-3.5" />
                  <span>Send Real Request & Parse Swift Struct</span>
                </>
              )}
            </button>
          </div>

          {/* Live Request Response Status Card */}
          {(responseStatus !== null || responseError) && (
            <div className="glass-panel p-5 bg-slate-950 text-white rounded-2xl border border-slate-800 shadow-xl space-y-3">
              <div className="flex items-center justify-between pb-2 border-b border-slate-800 text-xs font-mono">
                <div className="flex items-center gap-2">
                  <Terminal className="w-4 h-4 text-emerald-400" />
                  <span className="font-bold text-slate-200">Live Response Payload</span>
                </div>
                {responseStatus && (
                  <div className="flex items-center gap-2">
                    <span
                      className={`px-2 py-0.5 rounded text-[10px] font-bold border ${
                        responseStatus >= 200 && responseStatus < 300
                          ? "bg-emerald-500/20 text-emerald-300 border-emerald-500/40"
                          : "bg-rose-500/20 text-rose-300 border-rose-500/40"
                      }`}
                    >
                      {responseStatus} {responseStatusText}
                    </span>
                    {responseLatency !== null && (
                      <span className="text-[10px] text-slate-400">{responseLatency}ms</span>
                    )}
                  </div>
                )}
              </div>

              {responseError ? (
                <div className="flex items-start gap-2 p-3 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-300 text-xs font-mono">
                  <AlertCircle className="w-4 h-4 shrink-0 mt-0.5" />
                  <div>
                    <p className="font-bold">Browser CORS Notice:</p>
                    <p className="text-[11px] text-amber-200/80 leading-relaxed mt-1">
                      {responseError}
                    </p>
                  </div>
                </div>
              ) : (
                <div className="max-h-52 overflow-y-auto p-3 rounded-xl bg-slate-900 border border-slate-800 text-[11px] font-mono text-emerald-300 leading-relaxed">
                  <pre>{JSON.stringify(responseJson, null, 2)}</pre>
                </div>
              )}
            </div>
          )}
        </div>

        {/* Right Column: Swift 6 SPM Code Generator (7 cols) */}
        <div className="lg:col-span-7 glass-panel p-6 bg-white/95 dark:bg-slate-900/80 rounded-2xl border border-slate-200 dark:border-slate-800 shadow-xl space-y-4">
          <div className="flex flex-wrap items-center justify-between gap-3 pb-4 border-b border-slate-200 dark:border-slate-800">
            {/* Tabs */}
            <div className="flex flex-wrap items-center gap-1.5 bg-slate-100 dark:bg-slate-950 p-1 rounded-xl border border-slate-200 dark:border-slate-800 text-xs">
              <button
                onClick={() => setActiveTab("all")}
                className={`px-3 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${
                  activeTab === "all"
                    ? "bg-white dark:bg-slate-800 text-sky-600 dark:text-sky-400 shadow-sm"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                }`}
              >
                Full Swift File
              </button>
              <button
                onClick={() => setActiveTab("endpoint")}
                className={`px-3 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${
                  activeTab === "endpoint"
                    ? "bg-white dark:bg-slate-800 text-sky-600 dark:text-sky-400 shadow-sm"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                }`}
              >
                1. Endpoint
              </button>
              <button
                onClick={() => setActiveTab("model")}
                className={`px-3 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${
                  activeTab === "model"
                    ? "bg-white dark:bg-slate-800 text-sky-600 dark:text-sky-400 shadow-sm"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                }`}
              >
                2. Codable Model
              </button>
              <button
                onClick={() => setActiveTab("client")}
                className={`px-3 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${
                  activeTab === "client"
                    ? "bg-white dark:bg-slate-800 text-sky-600 dark:text-sky-400 shadow-sm"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                }`}
              >
                3. NetworkClient
              </button>
              <button
                onClick={() => setActiveTab("call")}
                className={`px-3 py-1 rounded-lg font-semibold transition-colors cursor-pointer ${
                  activeTab === "call"
                    ? "bg-white dark:bg-slate-800 text-sky-600 dark:text-sky-400 shadow-sm"
                    : "text-slate-600 dark:text-slate-400 hover:text-slate-900 dark:hover:text-white"
                }`}
              >
                4. Async/Await
              </button>
            </div>

            {/* Copy Button */}
            <button
              onClick={copyCode}
              className="px-3 py-1.5 rounded-xl bg-sky-500 hover:bg-sky-400 text-slate-950 font-bold text-xs flex items-center gap-1.5 transition-all shadow-md shadow-sky-500/20 cursor-pointer"
            >
              {copied ? <Check className="w-3.5 h-3.5" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{copied ? "Copied to Clipboard!" : "Copy Swift 6 Code"}</span>
            </button>
          </div>

          <div className="flex items-center justify-between text-xs font-mono text-slate-500 dark:text-slate-400 pb-1">
            <span className="flex items-center gap-1.5">
              <Code2 className="w-4 h-4 text-sky-500" />
              <span>Swift 6 Strict Concurrency Safe (.Sendable)</span>
            </span>
            <span className="text-[11px] text-emerald-600 dark:text-emerald-400 font-semibold">
              Zero External Dependencies
            </span>
          </div>

          {/* Code Viewer */}
          <div className="p-4 rounded-xl bg-slate-950 font-mono text-xs overflow-x-auto leading-relaxed text-sky-300 border border-slate-800 max-h-[580px] overflow-y-auto">
            <pre className="whitespace-pre font-mono leading-relaxed">
              <code>{getActiveCode()}</code>
            </pre>
          </div>
        </div>
      </div>
    </section>
  );
}
