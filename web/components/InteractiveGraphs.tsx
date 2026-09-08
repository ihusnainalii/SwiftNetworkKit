"use client";

import React, { useState, useId } from "react";
import {
  HardDrive,
  Timer,
  Zap,
  Database,
  BatteryCharging,
  TrendingUp,
  Activity,
  Cpu,
  Clock,
  ShieldCheck,
  RefreshCw,
  Wifi,
  WifiOff,
  Copy,
  Check
} from "lucide-react";

type GraphTab = "caching" | "jitter" | "concurrency" | "offline" | "calculator";

function GraphIcon({ id, className = "w-4 h-4" }: { id: string; className?: string }) {
  switch (id) {
    case "caching":
      return <HardDrive className={className} />;
    case "jitter":
      return <Timer className={className} />;
    case "concurrency":
      return <Zap className={className} />;
    case "offline":
      return <Database className={className} />;
    case "calculator":
      return <BatteryCharging className={className} />;
    default:
      return <Activity className={className} />;
  }
}

export function InteractiveGraphs() {
  const [activeTab, setActiveTab] = useState<GraphTab>("caching");
  const [copiedCode, setCopiedCode] = useState(false);

  // --- Caching State ---
  const [cachePayloadSizeKB, setCachePayloadSizeKB] = useState(120);
  const [networkType, setNetworkType] = useState<"5g" | "4g" | "3g" | "satellite">("4g");
  const [swrTimeSec, setSwrTimeSec] = useState(45);

  // --- Jitter & Backoff State ---
  const [retryAttempts, setRetryAttempts] = useState(5);
  const [concurrentFailingClients, setConcurrentFailingClients] = useState(500);
  const [baseDelay, setBaseDelay] = useState(1.0);

  // --- Concurrency / Token Refresh State ---
  const [concurrentRequests, setConcurrentRequests] = useState(40);

  // --- Offline Queue State ---
  const [isNetworkOnline, setIsNetworkOnline] = useState(true);
  const [offlineQueuedCount, setOfflineQueuedCount] = useState(24);
  const [queueReplayRate, setQueueReplayRate] = useState(6);

  // --- Calculator State ---
  const [dauCount, setDauCount] = useState(25000);
  const [reqsPerUser, setReqsPerUser] = useState(80);
  const [avgPayloadKB, setAvgPayloadKB] = useState(65);
  const [cacheHitPercent, setCacheHitPercent] = useState(82);

  // Unique IDs for SVG filters
  const svgPrefix = useId();

  // Network roundtrip latencies in ms
  const networkLatencies: Record<string, number> = {
    "5g": 48,
    "4g": 165,
    "3g": 720,
    satellite: 1100,
  };

  const l1MemoryLatency = 0.4;
  const l2DiskLatency = 5.2;
  const currentNetLatency = networkLatencies[networkType] || 165;
  const totalRawNetworkTime = (currentNetLatency + (cachePayloadSizeKB / 100) * 8).toFixed(1);
  const l1Speedup = Math.round(parseFloat(totalRawNetworkTime) / l1MemoryLatency);
  const l2Speedup = Math.round(parseFloat(totalRawNetworkTime) / l2DiskLatency);

  const handleCopyCode = (code: string) => {
    navigator.clipboard.writeText(code);
    setCopiedCode(true);
    setTimeout(() => setCopiedCode(false), 2000);
  };

  // Calculator computations
  const totalMonthlyRequests = dauCount * reqsPerUser * 30;
  const cachedMonthlyRequests = totalMonthlyRequests * (cacheHitPercent / 100);
  const bandwidthSavedGB = (cachedMonthlyRequests * avgPayloadKB) / (1024 * 1024);
  const monthlyCostSavedUSD = bandwidthSavedGB * 0.09;
  const batteryJoulesSaved = (cachedMonthlyRequests * 0.045).toFixed(0);

  return (
    <section id="graphs" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      {/* Section Title */}
      <div className="text-center max-w-3xl mx-auto mb-12">
        <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 border border-emerald-500/20 text-xs font-semibold mb-3 font-mono">
          <TrendingUp className="w-3.5 h-3.5" />
          <span>PERFORMANCE &amp; ARCHITECTURE GRAPHS</span>
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Visual Telemetry, Caching &amp; Concurrency Models
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Interactive latency waterfalls, two-tier cache hit analytics, exponential jitter curves, single-flight actor throughput, and network resource savings.
        </p>
      </div>

      {/* Main Tab Navigation */}
      <div className="flex flex-wrap items-center justify-center gap-2 mb-10">
        {[
          { id: "caching", label: "Two-Tier Caching & Latency", icon: "caching" },
          { id: "jitter", label: "Retry Jitter & Thundering Herd", icon: "jitter" },
          { id: "concurrency", label: "Actor Single-Flight Auth", icon: "concurrency" },
          { id: "offline", label: "Offline Queue & Drain Curve", icon: "offline" },
          { id: "calculator", label: "Bandwidth & Battery ROI", icon: "calculator" },
        ].map((tab) => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id as GraphTab)}
            className={`px-4 py-2.5 rounded-xl text-xs sm:text-sm font-semibold flex items-center gap-2 transition-all cursor-pointer shadow-sm ${
              activeTab === tab.id
                ? "bg-gradient-to-r from-orange-600 to-amber-600 text-white shadow-orange-500/25 shadow-lg scale-105"
                : "glass-panel bg-white/80 dark:bg-slate-900/60 text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white hover:border-orange-500/40"
            }`}
          >
            <GraphIcon id={tab.icon} className="w-4 h-4" />
            <span>{tab.label}</span>
          </button>
        ))}
      </div>

      {/* TAB CONTENT 1: TWO-TIER CACHING & LATENCY WATERFALL */}
      {activeTab === "caching" && (
        <div className="space-y-8 animate-in fade-in duration-300">
          {/* Top Controls Grid */}
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Cellular Connection Type</span>
                <span className="text-orange-600 dark:text-orange-400 font-bold uppercase">{networkType}</span>
              </label>
              <div className="grid grid-cols-4 gap-1.5">
                {(["5g", "4g", "3g", "satellite"] as const).map((net) => (
                  <button
                    key={net}
                    onClick={() => setNetworkType(net)}
                    className={`py-1.5 px-2 rounded-lg text-xs font-mono font-bold uppercase transition-all ${
                      networkType === net
                        ? "bg-orange-600 text-white shadow-md shadow-orange-600/30"
                        : "bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 hover:bg-slate-200 dark:hover:bg-slate-700"
                    }`}
                  >
                    {net}
                  </button>
                ))}
              </div>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Response Payload Size</span>
                <span className="text-sky-600 dark:text-sky-400 font-mono font-bold">{cachePayloadSizeKB} KB</span>
              </label>
              <input
                type="range"
                min={10}
                max={2048}
                step={10}
                value={cachePayloadSizeKB}
                onChange={(e) => setCachePayloadSizeKB(Number(e.target.value))}
                className="w-full accent-sky-500 cursor-pointer"
              />
              <div className="flex justify-between text-[10px] font-mono text-slate-400 mt-1">
                <span>10 KB (JSON)</span>
                <span>500 KB (Feed)</span>
                <span>2 MB (Image)</span>
              </div>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800 flex flex-col justify-between">
              <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400">CACHING ACCELERATION</span>
              <div className="flex items-baseline gap-3">
                <span className="text-3xl font-extrabold font-mono text-emerald-500">{l1Speedup}x</span>
                <span className="text-xs text-slate-600 dark:text-slate-400 leading-tight">
                  Faster than raw {networkType.toUpperCase()} network request
                </span>
              </div>
              <div className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                L1 NSCache Memory: <strong className="text-emerald-400">0.4ms</strong> | L2 Disk: <strong className="text-sky-400">5.2ms</strong>
              </div>
            </div>
          </div>

          {/* Graph 1: Latency Waterfall Chart */}
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            <div className="lg:col-span-7 glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-xl">
              <div className="flex items-center justify-between mb-6 pb-3 border-b border-slate-200 dark:border-slate-800">
                <div className="flex items-center gap-2">
                  <Activity className="w-4 h-4 text-orange-500" />
                  <h3 className="font-bold text-base text-slate-900 dark:text-white">
                    Two-Tier Cache Latency Breakdown (ms)
                  </h3>
                </div>
                <span className="text-xs font-mono px-2.5 py-1 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 font-bold">
                  Zero Network Overhead
                </span>
              </div>

              {/* Visual Bars */}
              <div className="space-y-5">
                {/* L1 Memory Cache */}
                <div>
                  <div className="flex items-center justify-between text-xs font-mono mb-1.5">
                    <span className="font-bold text-emerald-600 dark:text-emerald-400 flex items-center gap-1.5">
                      <Cpu className="w-3.5 h-3.5" /> L1 In-Memory NSCache
                    </span>
                    <span className="font-bold text-slate-900 dark:text-white">{l1MemoryLatency} ms ({l1Speedup}x speedup)</span>
                  </div>
                  <div className="h-6 w-full bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden flex items-center p-1">
                    <div
                      className="h-full bg-gradient-to-r from-emerald-500 to-teal-400 rounded-md transition-all duration-500 flex items-center px-2 text-[10px] font-mono text-white font-bold"
                      style={{ width: "2%" }}
                    >
                      0.4ms
                    </div>
                  </div>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                    Actor-isolated pointer retrieval. No disk reads, zero CPU thread contention.
                  </p>
                </div>

                {/* L2 Disk Cache */}
                <div>
                  <div className="flex items-center justify-between text-xs font-mono mb-1.5">
                    <span className="font-bold text-sky-600 dark:text-sky-400 flex items-center gap-1.5">
                      <HardDrive className="w-3.5 h-3.5" /> L2 Encrypted Disk Cache (SHA-256 Keyed)
                    </span>
                    <span className="font-bold text-slate-900 dark:text-white">{l2DiskLatency} ms ({l2Speedup}x speedup)</span>
                  </div>
                  <div className="h-6 w-full bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden flex items-center p-1">
                    <div
                      className="h-full bg-gradient-to-r from-sky-500 to-blue-500 rounded-md transition-all duration-500 flex items-center px-2 text-[10px] font-mono text-white font-bold"
                      style={{ width: "6%" }}
                    >
                      5.2ms
                    </div>
                  </div>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                    Local SSD read, schema validated, persists across application restarts and device reboots.
                  </p>
                </div>

                {/* 5G Network */}
                <div>
                  <div className="flex items-center justify-between text-xs font-mono mb-1.5">
                    <span className="font-bold text-slate-700 dark:text-slate-300 flex items-center gap-1.5">
                      <Wifi className="w-3.5 h-3.5 text-amber-500" /> 5G / Fiber Network Roundtrip
                    </span>
                    <span className="font-bold text-slate-900 dark:text-white">~48 ms</span>
                  </div>
                  <div className="h-6 w-full bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden flex items-center p-1">
                    <div
                      className="h-full bg-gradient-to-r from-amber-500 to-orange-400 rounded-md transition-all duration-500 flex items-center px-2 text-[10px] font-mono text-white font-bold"
                      style={{ width: "24%" }}
                    >
                      48ms
                    </div>
                  </div>
                </div>

                {/* Selected Network Roundtrip */}
                <div>
                  <div className="flex items-center justify-between text-xs font-mono mb-1.5">
                    <span className="font-bold text-rose-600 dark:text-rose-400 flex items-center gap-1.5">
                      <WifiOff className="w-3.5 h-3.5" /> Current Network Roundtrip ({networkType.toUpperCase()}) + Payload Transfer
                    </span>
                    <span className="font-bold text-rose-600 dark:text-rose-400">{totalRawNetworkTime} ms</span>
                  </div>
                  <div className="h-6 w-full bg-slate-100 dark:bg-slate-800 rounded-lg overflow-hidden flex items-center p-1">
                    <div
                      className="h-full bg-gradient-to-r from-rose-600 to-red-500 rounded-md transition-all duration-500 flex items-center px-2 text-[10px] font-mono text-white font-bold"
                      style={{ width: "100%" }}
                    >
                      {totalRawNetworkTime}ms
                    </div>
                  </div>
                  <p className="text-[11px] text-slate-500 dark:text-slate-400 mt-1">
                    Cellular radio wake-up latency + TLS 1.3 handshake + backend processing + TCP packet transfer.
                  </p>
                </div>
              </div>
            </div>

            {/* Hit Rate & Storage Breakdown */}
            <div className="lg:col-span-5 space-y-6">
              <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-xl">
                <h4 className="text-sm font-bold text-slate-900 dark:text-white mb-4 flex items-center justify-between">
                  <span>Cache Hit Distribution</span>
                  <span className="text-xs font-mono text-emerald-500 font-bold">94% Total Hit Ratio</span>
                </h4>

                {/* Segmented Bar */}
                <div className="h-4 w-full rounded-full overflow-hidden flex mb-3">
                  <div className="bg-emerald-500 h-full" style={{ width: "76%" }} title="76% L1 Memory Hit"></div>
                  <div className="bg-sky-500 h-full" style={{ width: "18%" }} title="18% L2 Disk Hit"></div>
                  <div className="bg-rose-500 h-full" style={{ width: "6%" }} title="6% Network Miss"></div>
                </div>

                <div className="grid grid-cols-3 gap-2 text-center text-xs font-mono">
                  <div className="p-2.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">L1 MEMORY</span>
                    <strong className="text-emerald-600 dark:text-emerald-400 text-sm">76%</strong>
                  </div>
                  <div className="p-2.5 rounded-xl bg-sky-500/10 border border-sky-500/20">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">L2 DISK</span>
                    <strong className="text-sky-600 dark:text-sky-400 text-sm">18%</strong>
                  </div>
                  <div className="p-2.5 rounded-xl bg-rose-500/10 border border-rose-500/20">
                    <span className="text-slate-500 dark:text-slate-400 text-[10px] block">NETWORK</span>
                    <strong className="text-rose-600 dark:text-rose-400 text-sm">6%</strong>
                  </div>
                </div>

                {/* Cache Inspector */}
                <div className="mt-5 pt-4 border-t border-slate-200 dark:border-slate-800 space-y-2 text-xs font-mono">
                  <div className="flex justify-between">
                    <span className="text-slate-500">Cache Key:</span>
                    <span className="text-sky-400 truncate max-w-[190px]">sha256(GET:/v1/feed:etag)</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Memory Budget:</span>
                    <span className="text-slate-900 dark:text-slate-200">18.4 MB / 50 MB</span>
                  </div>
                  <div className="flex justify-between">
                    <span className="text-slate-500">Disk Quota:</span>
                    <span className="text-slate-900 dark:text-slate-200">142 MB / 256 MB (LRU Eviction)</span>
                  </div>
                </div>
              </div>

              {/* Swift 6 Implementation Snippet */}
              <div className="glass-panel p-4 bg-slate-950 border border-slate-800 rounded-xl text-xs font-mono">
                <div className="flex items-center justify-between mb-2 text-slate-400">
                  <span className="text-[11px] text-sky-400">SwiftNetworkKit Caching API</span>
                  <button
                    onClick={() =>
                      handleCopyCode(`let client = NetworkClient(
    configuration: NetworkConfiguration(
        baseURL: "https://api.example.com",
        cacheStorage: TwoTierCacheStorage(
            memoryLimitBytes: 50 * 1024 * 1024,
            diskLimitBytes: 256 * 1024 * 1024
        ),
        cachePolicy: .staleWhileRevalidate(maxAge: 60, staleWindow: 300)
    )
)`)
                    }
                    className="hover:text-white transition-colors"
                  >
                    {copiedCode ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
                  </button>
                </div>
                <pre className="text-slate-300 overflow-x-auto text-[11px] leading-relaxed">
                  <code>{`// Declarative Two-Tier Cache with Stale-While-Revalidate
struct FeedEndpoint: Endpoint {
    typealias Response = FeedResponse
    var path: String { "/feed" }
    var cachePolicy: CachePolicy {
        .staleWhileRevalidate(maxAge: 60, staleWindow: 300)
    }
}`}</code>
                </pre>
              </div>
            </div>
          </div>

          {/* Stale-While-Revalidate (SWR) Visual Step Simulator */}
          <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-xl">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6 pb-4 border-b border-slate-200 dark:border-slate-800">
              <div>
                <h3 className="font-bold text-base text-slate-900 dark:text-white flex items-center gap-2">
                  <Clock className="w-4 h-4 text-sky-500" />
                  <span>Stale-While-Revalidate (SWR) &amp; TTL Lifecycle</span>
                </h3>
                <p className="text-xs text-slate-500 dark:text-slate-400 mt-0.5">
                  Instant UI response from cache while background actor silently fetches freshest data.
                </p>
              </div>
              <div className="flex items-center gap-3">
                <span className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300">
                  Elapsed Time: <strong className="text-sky-500 font-mono text-sm">{swrTimeSec}s</strong>
                </span>
                <input
                  type="range"
                  min={0}
                  max={120}
                  value={swrTimeSec}
                  onChange={(e) => setSwrTimeSec(Number(e.target.value))}
                  className="w-36 accent-sky-500 cursor-pointer"
                />
              </div>
            </div>

            {/* Timeline Progress Bar */}
            <div className="relative mb-6">
              <div className="h-3 w-full bg-slate-200 dark:bg-slate-800 rounded-full overflow-hidden flex">
                <div className="bg-emerald-500 h-full" style={{ width: "25%" }} title="0s - 30s: Fresh Cache Window"></div>
                <div className="bg-sky-500 h-full" style={{ width: "50%" }} title="30s - 90s: Stale-While-Revalidate Window"></div>
                <div className="bg-amber-500 h-full" style={{ width: "25%" }} title="90s - 120s+: Expired Network Mandatory"></div>
              </div>

              {/* Cursor indicator */}
              <div
                className="absolute top-[-6px] w-4 h-6 bg-white border-2 border-slate-900 dark:border-white rounded-md shadow-md transform -translate-x-1/2 transition-all duration-150"
                style={{ left: `${(swrTimeSec / 120) * 100}%` }}
              ></div>

              <div className="flex justify-between text-[11px] font-mono text-slate-500 mt-2">
                <span>0s (Fetch)</span>
                <span className="text-emerald-500 font-bold">30s (Max-Age Expired)</span>
                <span className="text-sky-500 font-bold">90s (SWR Window Closes)</span>
                <span className="text-amber-500">120s (Expired)</span>
              </div>
            </div>

            {/* Dynamic Status Card */}
            <div className="p-4 rounded-xl border flex items-center justify-between gap-4 transition-all bg-slate-50 dark:bg-slate-950 border-slate-200 dark:border-slate-800">
              {swrTimeSec <= 30 ? (
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 flex items-center justify-center shrink-0">
                    <Check className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-emerald-600 dark:text-emerald-400">STATUS: FRESH CACHE HIT (&lt;30s)</h4>
                    <p className="text-xs text-slate-600 dark:text-slate-300">
                      Returns instant L1 Memory cache payload in <strong>0.4ms</strong>. Zero network activity, zero battery consumption.
                    </p>
                  </div>
                </div>
              ) : swrTimeSec <= 90 ? (
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-sky-500/10 text-sky-600 dark:text-sky-400 flex items-center justify-center shrink-0 animate-pulse">
                    <RefreshCw className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-sky-600 dark:text-sky-400">
                      STATUS: STALE-WHILE-REVALIDATE ACTIVE (30s to 90s)
                    </h4>
                    <p className="text-xs text-slate-600 dark:text-slate-300">
                      Instantly yields cached data to UI (0.4ms) + launches asynchronous Swift actor task in background to update cache without UI latency!
                    </p>
                  </div>
                </div>
              ) : (
                <div className="flex items-center gap-3">
                  <div className="w-9 h-9 rounded-xl bg-amber-500/10 text-amber-600 dark:text-amber-400 flex items-center justify-center shrink-0">
                    <Wifi className="w-5 h-5" />
                  </div>
                  <div>
                    <h4 className="text-xs font-bold text-amber-600 dark:text-amber-400">STATUS: CACHE EXPIRED (&gt;90s)</h4>
                    <p className="text-xs text-slate-600 dark:text-slate-300">
                      Mandatory network fetch with HTTP <code className="text-[11px] font-mono">If-None-Match</code> conditional header. Fast 304 Not Modified if unchanged.
                    </p>
                  </div>
                </div>
              )}
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT 2: EXPONENTIAL JITTER & THUNDERING HERD GRAPH */}
      {activeTab === "jitter" && (
        <div className="space-y-8 animate-in fade-in duration-300">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Concurrent Failing Clients</span>
                <span className="text-orange-600 dark:text-orange-400 font-mono font-bold">{concurrentFailingClients} clients</span>
              </label>
              <input
                type="range"
                min={50}
                max={3000}
                step={50}
                value={concurrentFailingClients}
                onChange={(e) => setConcurrentFailingClients(Number(e.target.value))}
                className="w-full accent-orange-500 cursor-pointer"
              />
              <span className="text-[10px] font-mono text-slate-400 mt-1 block">
                Simulates outage recovery &amp; retry stampede
              </span>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Base Delay (t₀)</span>
                <span className="text-sky-600 dark:text-sky-400 font-mono font-bold">{baseDelay.toFixed(1)}s</span>
              </label>
              <input
                type="range"
                min={0.5}
                max={4.0}
                step={0.5}
                value={baseDelay}
                onChange={(e) => setBaseDelay(Number(e.target.value))}
                className="w-full accent-sky-500 cursor-pointer"
              />
              <span className="text-[10px] font-mono text-slate-400 mt-1 block">
                Initial backoff multiplier: t = random(0, t₀ · 2ⁿ)
              </span>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800 flex flex-col justify-between">
              <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400">SERVER SPIKE REDUCTION</span>
              <div className="flex items-baseline gap-3">
                <span className="text-3xl font-extrabold font-mono text-emerald-500">87%</span>
                <span className="text-xs text-slate-600 dark:text-slate-400 leading-tight">
                  Lower peak RPS with SwiftNetworkKit Full Jitter
                </span>
              </div>
              <div className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                Eliminates server thundering herd cascade
              </div>
            </div>
          </div>

          {/* Interactive SVG Curve Graph */}
          <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-xl">
            <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-6 pb-3 border-b border-slate-200 dark:border-slate-800">
              <div className="flex items-center gap-2">
                <Timer className="w-5 h-5 text-orange-500" />
                <h3 className="font-bold text-base text-slate-900 dark:text-white">
                  Retry Delay Distribution: Jitter vs Exponential vs Flat
                </h3>
              </div>
              <div className="flex flex-wrap items-center gap-4 text-xs font-mono font-semibold">
                <span className="flex items-center gap-1.5 text-rose-500">
                  <span className="w-3 h-3 rounded-full bg-rose-500"></span> Flat Retry (Stampede!)
                </span>
                <span className="flex items-center gap-1.5 text-amber-500">
                  <span className="w-3 h-3 rounded-full bg-amber-500"></span> Pure Exponential
                </span>
                <span className="flex items-center gap-1.5 text-emerald-500">
                  <span className="w-3 h-3 rounded-full bg-emerald-500"></span> SwiftNetworkKit Full Jitter
                </span>
              </div>
            </div>

            {/* SVG Visual Canvas */}
            <div className="w-full overflow-x-auto">
              <svg viewBox="0 0 800 320" className="w-full h-auto min-w-[640px] font-mono text-xs">
                <defs>
                  <linearGradient id={`${svgPrefix}-jitter-grad`} x1="0" y1="0" x2="0" y2="1">
                    <stop offset="0%" stopColor="#10b981" stopOpacity="0.35" />
                    <stop offset="100%" stopColor="#10b981" stopOpacity="0.0" />
                  </linearGradient>
                </defs>

                {/* Grid Lines */}
                {[60, 120, 180, 240].map((y) => (
                  <line
                    key={y}
                    x1="60"
                    y1={y}
                    x2="760"
                    y2={y}
                    stroke="currentColor"
                    className="text-slate-200 dark:text-slate-800"
                    strokeDasharray="4 4"
                  />
                ))}

                {/* Axes */}
                <line x1="60" y1="280" x2="760" y2="280" stroke="currentColor" className="text-slate-400" strokeWidth="1.5" />
                <line x1="60" y1="40" x2="60" y2="280" stroke="currentColor" className="text-slate-400" strokeWidth="1.5" />

                {/* Y-Axis Labels (Delay in Seconds) */}
                <text x="20" y="50" fill="currentColor" className="text-[10px] text-slate-400">32s</text>
                <text x="20" y="120" fill="currentColor" className="text-[10px] text-slate-400">16s</text>
                <text x="20" y="180" fill="currentColor" className="text-[10px] text-slate-400">8s</text>
                <text x="20" y="240" fill="currentColor" className="text-[10px] text-slate-400">2s</text>
                <text x="20" y="284" fill="currentColor" className="text-[10px] text-slate-400">0s</text>

                {/* X-Axis Labels (Retry Attempt) */}
                {[
                  { attempt: "Attempt 1", x: 120 },
                  { attempt: "Attempt 2", x: 260 },
                  { attempt: "Attempt 3", x: 400 },
                  { attempt: "Attempt 4", x: 540 },
                  { attempt: "Attempt 5", x: 680 },
                ].map((item, idx) => (
                  <text key={idx} x={item.x} y="302" textAnchor="middle" fill="currentColor" className="text-[11px] text-slate-400 font-bold">
                    {item.attempt}
                  </text>
                ))}

                {/* 1. Flat Retry Curve (Red dashed horizontal spikes) */}
                <path
                  d="M 60 240 L 120 240 L 260 240 L 400 240 L 540 240 L 680 240"
                  fill="none"
                  stroke="#f43f5e"
                  strokeWidth="3"
                  strokeDasharray="6 4"
                />

                {/* 2. Pure Exponential Curve (Amber solid line) */}
                <path
                  d="M 60 270 Q 200 260, 260 240 T 400 180 T 540 120 T 680 50"
                  fill="none"
                  stroke="#f59e0b"
                  strokeWidth="3"
                />

                {/* 3. Jitter Spread Area (Green filled area showing random uniform distribution) */}
                <path
                  d="M 60 280 L 120 270 L 260 245 L 400 190 L 540 130 L 680 60 L 680 280 L 60 280 Z"
                  fill={`url(#${svgPrefix}-jitter-grad)`}
                />
                <path
                  d="M 60 280 L 120 272 L 260 252 L 400 205 L 540 155 L 680 85"
                  fill="none"
                  stroke="#10b981"
                  strokeWidth="3"
                />

                {/* Point markers for Jitter */}
                {[
                  { cx: 120, cy: 272, label: "0.4s" },
                  { cx: 260, cy: 252, label: "1.8s" },
                  { cx: 400, cy: 205, label: "5.4s" },
                  { cx: 540, cy: 155, label: "11.2s" },
                  { cx: 680, cy: 85, label: "24.6s" },
                ].map((pt, i) => (
                  <g key={i}>
                    <circle cx={pt.cx} cy={pt.cy} r="5" fill="#10b981" stroke="#ffffff" strokeWidth="2" />
                    <text x={pt.cx} y={pt.cy - 10} textAnchor="middle" fill="#10b981" className="text-[10px] font-bold">
                      {pt.label}
                    </text>
                  </g>
                ))}
              </svg>
            </div>

            {/* Explanatory Callout */}
            <div className="grid grid-cols-1 md:grid-cols-3 gap-4 mt-6 pt-6 border-t border-slate-200 dark:border-slate-800 text-xs">
              <div className="p-3.5 rounded-xl bg-rose-500/10 border border-rose-500/20 text-rose-700 dark:text-rose-300">
                <strong className="block font-bold mb-1">Flat / Fixed Retry</strong>
                If 1,000 devices fail at t=0, exactly 1,000 requests hit the server at t=2.0s, creating a recurring wave that crashes the recovering backend.
              </div>
              <div className="p-3.5 rounded-xl bg-amber-500/10 border border-amber-500/20 text-amber-700 dark:text-amber-300">
                <strong className="block font-bold mb-1">Pure Exponential</strong>
                Delays increase (2s, 4s, 8s, 16s), but synchronized clients still attack the server simultaneously in concentrated harmonic spikes.
              </div>
              <div className="p-3.5 rounded-xl bg-emerald-500/10 border border-emerald-500/20 text-emerald-700 dark:text-emerald-300">
                <strong className="block font-bold mb-1">SwiftNetworkKit Full Jitter</strong>
                Applies decorrelated uniform jitter. Requests are evenly smoothed across time, guaranteeing smooth server load during outages.
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT 3: ACTOR CONCURRENCY & SINGLE-FLIGHT AUTH */}
      {activeTab === "concurrency" && (
        <div className="space-y-8 animate-in fade-in duration-300">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Concurrent 401 Callers</span>
                <span className="text-sky-600 dark:text-sky-400 font-mono font-bold">{concurrentRequests} simultaneous</span>
              </label>
              <input
                type="range"
                min={5}
                max={100}
                step={5}
                value={concurrentRequests}
                onChange={(e) => setConcurrentRequests(Number(e.target.value))}
                className="w-full accent-sky-500 cursor-pointer"
              />
              <span className="text-[10px] font-mono text-slate-400 mt-1 block">
                Parallel async tasks requesting refreshed tokens
              </span>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400">ACTOR DEDUPLICATION EFFICIENCY</span>
              <div className="flex items-baseline gap-3 my-1">
                <span className="text-3xl font-extrabold font-mono text-sky-400">1</span>
                <span className="text-xs text-slate-600 dark:text-slate-400 leading-tight">
                  Single HTTP Refresh Request executed (vs {concurrentRequests} in traditional stacks)
                </span>
              </div>
              <div className="text-[11px] font-mono text-emerald-400">
                {concurrentRequests - 1} redundant token refreshes cancelled
              </div>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800 flex flex-col justify-between">
              <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400">DATA RACES &amp; DEADLOCKS</span>
              <div className="flex items-baseline gap-3">
                <span className="text-3xl font-extrabold font-mono text-emerald-500">0</span>
                <span className="text-xs text-slate-600 dark:text-slate-400 leading-tight">
                  Swift 6 Strict Concurrency Isolation
                </span>
              </div>
              <div className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                13 Actors, Sendable-only message passing
              </div>
            </div>
          </div>

          {/* Side-by-side Visual Comparison Chart */}
          <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
            {/* Traditional Contention */}
            <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-rose-500/20 shadow-xl">
              <div className="flex items-center justify-between pb-3 mb-4 border-b border-rose-500/20">
                <h4 className="font-bold text-sm text-rose-600 dark:text-rose-400 flex items-center gap-2">
                  <span>Traditional Networking (Alamofire / URLSession)</span>
                </h4>
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-rose-500/10 text-rose-500 font-bold">
                  O(N) Dispatched Requests
                </span>
              </div>

              <div className="space-y-3 font-mono text-xs">
                <div className="p-3 rounded-xl bg-slate-950 border border-slate-800">
                  <div className="text-slate-400 text-[11px] mb-1">Network Refresh Requests Fired:</div>
                  <div className="text-2xl font-bold text-rose-500">{concurrentRequests} HTTP Requests</div>
                </div>

                <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 space-y-1 text-slate-300 text-[11px]">
                  <div className="text-rose-400 font-bold">Race Condition Cascade:</div>
                  <div>- Thread 1 fires POST /auth/refresh and rotates refreshToken</div>
                  <div>- Thread 2 fires POST /auth/refresh with old token and gets 401 INVALID</div>
                  <div>- App logs user out involuntarily (Session Lost)</div>
                </div>
              </div>
            </div>

            {/* SwiftNetworkKit Actor Single-Flight */}
            <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-emerald-500/20 shadow-xl">
              <div className="flex items-center justify-between pb-3 mb-4 border-b border-emerald-500/20">
                <h4 className="font-bold text-sm text-emerald-600 dark:text-emerald-400 flex items-center gap-2">
                  <ShieldCheck className="w-4 h-4" />
                  <span>SwiftNetworkKit TokenManager (Actor Isolated)</span>
                </h4>
                <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-emerald-500/10 text-emerald-500 font-bold">
                  O(1) Single-Flight
                </span>
              </div>

              <div className="space-y-3 font-mono text-xs">
                <div className="p-3 rounded-xl bg-slate-950 border border-slate-800">
                  <div className="text-slate-400 text-[11px] mb-1">Network Refresh Requests Fired:</div>
                  <div className="text-2xl font-bold text-emerald-400">1 HTTP Request</div>
                </div>

                <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 space-y-1 text-slate-300 text-[11px]">
                  <div className="text-emerald-400 font-bold">Actor Single-Flight Queue:</div>
                  <div>- Thread 1 spawns actor-isolated Task&lt;TokenPair, Error&gt;</div>
                  <div>- Threads 2..{concurrentRequests} safely suspend awaiting the single task</div>
                  <div>- All {concurrentRequests} requests resume in parallel with fresh token</div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT 4: OFFLINE SPOOLING & DRAIN DYNAMICS */}
      {activeTab === "offline" && (
        <div className="space-y-8 animate-in fade-in duration-300">
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4">
            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Network Link Status</span>
                <span className={`font-mono font-bold uppercase ${isNetworkOnline ? "text-emerald-500" : "text-rose-500"}`}>
                  {isNetworkOnline ? "Online (NWPathMonitor)" : "Offline (Spooling)"}
                </span>
              </label>
              <button
                onClick={() => setIsNetworkOnline(!isNetworkOnline)}
                className={`w-full py-2 px-4 rounded-xl text-xs font-mono font-bold flex items-center justify-center gap-2 transition-all cursor-pointer shadow-md ${
                  isNetworkOnline
                    ? "bg-rose-600 hover:bg-rose-500 text-white shadow-rose-600/30"
                    : "bg-emerald-600 hover:bg-emerald-500 text-white shadow-emerald-600/30"
                }`}
              >
                {isNetworkOnline ? <WifiOff className="w-3.5 h-3.5" /> : <Wifi className="w-3.5 h-3.5" />}
                <span>{isNetworkOnline ? "Simulate Connection Drop" : "Simulate Reconnection"}</span>
              </button>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800">
              <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-center justify-between mb-2">
                <span>Spool Buffer Size</span>
                <span className="text-purple-600 dark:text-purple-400 font-mono font-bold">{offlineQueuedCount} requests</span>
              </label>
              <input
                type="range"
                min={0}
                max={100}
                value={offlineQueuedCount}
                onChange={(e) => setOfflineQueuedCount(Number(e.target.value))}
                className="w-full accent-purple-500 cursor-pointer"
              />
              <span className="text-[10px] font-mono text-slate-400 mt-1 block">
                Persisted securely in EncryptedDiskStorage
              </span>
            </div>

            <div className="glass-panel p-5 bg-white/90 dark:bg-slate-900/70 border border-slate-200 dark:border-slate-800 flex flex-col justify-between">
              <span className="text-xs font-mono font-bold text-slate-500 dark:text-slate-400">REPLAY DRAIN THROUGHPUT</span>
              <div className="flex items-baseline gap-3">
                <span className="text-3xl font-extrabold font-mono text-purple-400">{queueReplayRate} req/s</span>
                <span className="text-xs text-slate-600 dark:text-slate-400 leading-tight">
                  Rate-limited concurrency prevents backend saturation
                </span>
              </div>
              <div className="text-[11px] font-mono text-slate-500 dark:text-slate-400">
                Dependency-ordered FIFO dispatch
              </div>
            </div>
          </div>

          {/* Queue Drain Visualization */}
          <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-xl">
            <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-200 dark:border-slate-800">
              <h3 className="font-bold text-base text-slate-900 dark:text-white flex items-center gap-2">
                <Database className="w-4 h-4 text-purple-500" />
                <span>Offline Spool &amp; Replay Buffer Dynamics</span>
              </h3>
              <span className="text-xs font-mono text-slate-400">RFC 7234 &amp; Persistent Mutation Queue</span>
            </div>

            <div className="grid grid-cols-1 md:grid-cols-4 gap-3 text-xs font-mono">
              <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800">
                <span className="text-slate-500 text-[10px] block mb-1">CURRENT STATUS</span>
                <span className={isNetworkOnline ? "text-emerald-400 font-bold" : "text-amber-400 font-bold"}>
                  {isNetworkOnline ? "Replaying Spool" : "Spooling to Disk"}
                </span>
              </div>
              <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800">
                <span className="text-slate-500 text-[10px] block mb-1">DRAIN DURATION</span>
                <span className="text-sky-400 font-bold">
                  {isNetworkOnline ? `${(offlineQueuedCount / queueReplayRate).toFixed(1)}s` : "Paused (Offline)"}
                </span>
              </div>
              <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800">
                <span className="text-slate-500 text-[10px] block mb-1">MUTATION INTEGRITY</span>
                <span className="text-emerald-400 font-bold">100% Guaranteed</span>
              </div>
              <div className="p-3.5 rounded-xl bg-slate-950 border border-slate-800">
                <span className="text-slate-500 text-[10px] block mb-1">DATA LOSS</span>
                <span className="text-purple-400 font-bold">0 Dropped Packets</span>
              </div>
            </div>
          </div>
        </div>
      )}

      {/* TAB CONTENT 5: BANDWIDTH, BATTERY & ROI CALCULATOR */}
      {activeTab === "calculator" && (
        <div className="space-y-8 animate-in fade-in duration-300">
          <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
            {/* Input Controls */}
            <div className="lg:col-span-6 glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-slate-200 dark:border-slate-800 shadow-xl space-y-5">
              <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center gap-2 pb-3 border-b border-slate-200 dark:border-slate-800">
                <BatteryCharging className="w-4 h-4 text-emerald-500" />
                <span>App Scale &amp; Traffic Parameters</span>
              </h3>

              <div>
                <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-between justify-between mb-1.5">
                  <span>Daily Active Users (DAU)</span>
                  <span className="text-emerald-500 font-mono font-bold">{dauCount.toLocaleString()}</span>
                </label>
                <input
                  type="range"
                  min={1000}
                  max={250000}
                  step={1000}
                  value={dauCount}
                  onChange={(e) => setDauCount(Number(e.target.value))}
                  className="w-full accent-emerald-500 cursor-pointer"
                />
              </div>

              <div>
                <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-between justify-between mb-1.5">
                  <span>Requests Per User / Day</span>
                  <span className="text-sky-500 font-mono font-bold">{reqsPerUser} requests</span>
                </label>
                <input
                  type="range"
                  min={10}
                  max={300}
                  step={5}
                  value={reqsPerUser}
                  onChange={(e) => setReqsPerUser(Number(e.target.value))}
                  className="w-full accent-sky-500 cursor-pointer"
                />
              </div>

              <div>
                <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-between justify-between mb-1.5">
                  <span>Average Response Payload Size</span>
                  <span className="text-purple-500 font-mono font-bold">{avgPayloadKB} KB</span>
                </label>
                <input
                  type="range"
                  min={5}
                  max={500}
                  step={5}
                  value={avgPayloadKB}
                  onChange={(e) => setAvgPayloadKB(Number(e.target.value))}
                  className="w-full accent-purple-500 cursor-pointer"
                />
              </div>

              <div>
                <label className="text-xs font-mono font-bold text-slate-700 dark:text-slate-300 flex items-between justify-between mb-1.5">
                  <span>Two-Tier Cache Hit Rate</span>
                  <span className="text-amber-500 font-mono font-bold">{cacheHitPercent}%</span>
                </label>
                <input
                  type="range"
                  min={40}
                  max={98}
                  step={1}
                  value={cacheHitPercent}
                  onChange={(e) => setCacheHitPercent(Number(e.target.value))}
                  className="w-full accent-amber-500 cursor-pointer"
                />
              </div>
            </div>

            {/* Calculated Results */}
            <div className="lg:col-span-6 space-y-4">
              <div className="glass-panel p-6 bg-white/95 dark:bg-slate-900/80 border border-emerald-500/30 shadow-xl space-y-4">
                <h3 className="text-base font-bold text-slate-900 dark:text-white flex items-center justify-between pb-3 border-b border-slate-200 dark:border-slate-800">
                  <span>Monthly Infrastructure &amp; Device Savings</span>
                  <span className="text-xs font-mono px-2.5 py-1 rounded bg-emerald-500/10 text-emerald-500 font-bold">
                    Production Estimate
                  </span>
                </h3>

                <div className="grid grid-cols-2 gap-4">
                  <div className="p-4 rounded-xl bg-slate-950 border border-slate-800">
                    <span className="text-[11px] font-mono text-slate-400 block mb-1">BANDWIDTH SAVED</span>
                    <span className="text-2xl font-bold font-mono text-emerald-400">
                      {bandwidthSavedGB > 1024
                        ? `${(bandwidthSavedGB / 1024).toFixed(1)} TB`
                        : `${bandwidthSavedGB.toFixed(0)} GB`}
                    </span>
                    <span className="text-[10px] text-slate-500 block mt-1">per month</span>
                  </div>

                  <div className="p-4 rounded-xl bg-slate-950 border border-slate-800">
                    <span className="text-[11px] font-mono text-slate-400 block mb-1">EGRESS BILL SAVINGS</span>
                    <span className="text-2xl font-bold font-mono text-sky-400">
                      ${monthlyCostSavedUSD.toLocaleString("en-US", { maximumFractionDigits: 0 })}
                    </span>
                    <span className="text-[10px] text-slate-500 block mt-1">AWS / GCP / Cloudflare</span>
                  </div>

                  <div className="p-4 rounded-xl bg-slate-950 border border-slate-800">
                    <span className="text-[11px] font-mono text-slate-400 block mb-1">BATTERY ENERGY CONSERVED</span>
                    <span className="text-2xl font-bold font-mono text-amber-400">
                      {(parseInt(batteryJoulesSaved) / 3600).toFixed(1)} Wh
                    </span>
                    <span className="text-[10px] text-slate-500 block mt-1">Cellular radio sleep</span>
                  </div>

                  <div className="p-4 rounded-xl bg-slate-950 border border-slate-800">
                    <span className="text-[11px] font-mono text-slate-400 block mb-1">TOTAL REQUESTS OFF-LOADED</span>
                    <span className="text-2xl font-bold font-mono text-purple-400">
                      {(cachedMonthlyRequests / 1_000_000).toFixed(1)}M
                    </span>
                    <span className="text-[10px] text-slate-500 block mt-1">Fewer server roundtrips</span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      )}
    </section>
  );
}
