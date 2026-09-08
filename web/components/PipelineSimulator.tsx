"use client";

import React, { useState } from "react";
import {
  Activity,
  CheckCircle,
  RefreshCw,
  Timer,
  WifiOff,
  Terminal,
  Check,
  UploadCloud,
  DownloadCloud
} from "lucide-react";

interface Step {
  id: string;
  title: string;
  subtitle: string;
  desc: string;
  headers: Record<string, string>;
  status: string;
}

const PIPELINE_STEPS: Step[] = [
  {
    id: "endpoint",
    title: "Endpoint Definition",
    subtitle: "Type-safe URL & Request Construction",
    desc: "Encapsulates path (/v1/users/me), HTTP method (.get), headers, query params, and AuthRequirement (.required). Type-safe Response binding.",
    headers: { Accept: "application/json", "Content-Type": "application/json" },
    status: "Ready to build URLRequest",
  },
  {
    id: "interceptors-req",
    title: "Request Interceptors",
    subtitle: "Distributed Tracing & Header Adaptation",
    desc: "Mutates outgoing requests. Injects distributed tracing (X-Request-ID, X-Correlation-ID), API keys, and device metadata before network hop.",
    headers: { "X-Request-ID": "req_98a72f01", "X-Correlation-ID": "tx_checkout_88" },
    status: "Headers adapted & Tracing injected",
  },
  {
    id: "token-mgr",
    title: "TokenManager (Swift Actor)",
    subtitle: "Single-Flight Auth & Keychain Cache",
    desc: "Actor-isolated single-flight auth engine. Securely pulls tokens from KeychainTokenStorage and handles automatic 401 refresh queueing without data races.",
    headers: { Authorization: "Bearer eyJhbGciOi...[REDACTED]" },
    status: "Bearer token injected from Keychain",
  },
  {
    id: "transport",
    title: "Transport & SSL Pinning",
    subtitle: "SPKI SHA-256 TLS Handshake",
    desc: "Executes over URLSession. Performs zero-dependency SPKI SHA-256 Public Key or Certificate Pinning trust evaluation during TLS handshake.",
    headers: { "TLS-Version": "TLSv1.3", "SPKI-Pin-Status": "Verified (sha256/9kE7...)" },
    status: "Transport session active",
  },
  {
    id: "retry-engine",
    title: "Retry & Backoff Engine",
    subtitle: "Full Jitter Exponential Algorithm",
    desc: "Evaluates HTTP status (5xx, 429, 408) or network drops. Uses exponential backoff with full jitter and honors Retry-After headers.",
    headers: { "Retry-Policy": "Exponential (max 3)", "Attempts-Count": "1" },
    status: "Idempotency verified",
  },
  {
    id: "interceptors-res",
    title: "Response Interceptors",
    subtitle: "Status Code Validation & Interception",
    desc: "Inspects raw HTTP response. Returns InterceptOutcome (.proceed, .retry, .substitute, .fail) or intercepts 2FA challenges.",
    headers: { Server: "cloudflare", "Content-Type": "application/json" },
    status: "Validation passed",
  },
  {
    id: "decoding",
    title: "Typed JSON Decoder",
    subtitle: "Swift Decodable & ISO8601 Parsing",
    desc: "Decodes raw JSON Data into Swift Decodable model with automatic ISO8601 date decoding and camelCase conversion.",
    headers: { "Parsed-Type": "UserProfile.self", "Bytes-Received": "1,420 bytes" },
    status: "Successfully decoded into struct UserProfile",
  },
  {
    id: "metrics-logs",
    title: "Redacting Logger & Metrics",
    subtitle: "Telemetry Snapshot & Token Redaction",
    desc: "Records duration, p95 latency, and status code histograms in InMemoryMetrics while redacting sensitive tokens in ConsoleNetworkLogger.",
    headers: { Duration: "48.2ms", Status: "200 OK", "Auth-Logged": "REDACTED" },
    status: "Recorded to InMemoryMetrics snapshot",
  },
];

export function PipelineSimulator() {
  const [activeIndex, setActiveIndex] = useState(0);
  const [passedSteps, setPassedSteps] = useState<number[]>([]);
  const [isRunning, setIsRunning] = useState(false);
  const [logs, setLogs] = useState<string[]>([
    "Select a scenario above to simulate the live networking packet flow...",
  ]);

  const activeStep = PIPELINE_STEPS[activeIndex];

  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  const markPassed = (index: number) => {
    setPassedSteps((prev) => (prev.includes(index) ? prev : [...prev, index]));
  };

  const runScenario = async (type: "success" | "auth" | "retry" | "drop" | "upload" | "download") => {
    if (isRunning) return;
    setIsRunning(true);
    setPassedSteps([]);
    setLogs([`🚀 Initializing request simulation: [${type.toUpperCase()}]...`]);

    if (type === "success") {
      for (let i = 0; i < PIPELINE_STEPS.length; i++) {
        setActiveIndex(i);
        setLogs((prev) => [...prev, `➔ Step ${i + 1}: ${PIPELINE_STEPS[i].title} - Completed`]);
        markPassed(i);
        await sleep(400);
      }
      setLogs((prev) => [...prev, "✅ HTTP 200 OK: UserProfile successfully received & decoded in 42ms"]);
    } else if (type === "auth") {
      setActiveIndex(0);
      markPassed(0);
      setLogs((prev) => [...prev, "➔ Step 1: Endpoint GetProfile configured with AuthRequirement.required"]);
      await sleep(350);

      setActiveIndex(1);
      markPassed(1);
      setLogs((prev) => [...prev, "➔ Step 2: RequestInterceptors attached correlation ID tx_401"]);
      await sleep(350);

      setActiveIndex(2);
      markPassed(2);
      setLogs((prev) => [...prev, "➔ Step 3: TokenManager injected cached accessToken"]);
      await sleep(350);

      setActiveIndex(3);
      markPassed(3);
      setLogs((prev) => [...prev, "➔ Step 4: Transport sent request to https://api.example.com/me"]);
      await sleep(400);

      setLogs((prev) => [...prev, "⚠️ Server returned HTTP 401 Unauthorized (Expired Access Token)"]);
      await sleep(400);

      setActiveIndex(2);
      setLogs((prev) => [...prev, "🔄 TokenManager Actor intercepted 401. Queuing callers & executing single-flight refresh block..."]);
      await sleep(700);

      setLogs((prev) => [...prev, "🔑 Refresh token exchange succeeded! Saved new accessToken to KeychainTokenStorage"]);
      await sleep(400);

      setActiveIndex(3);
      setLogs((prev) => [...prev, "🔁 Automatically retrying original request with new Token..."]);
      await sleep(400);

      setActiveIndex(5);
      markPassed(4);
      markPassed(5);
      await sleep(300);

      setActiveIndex(6);
      markPassed(6);
      setLogs((prev) => [...prev, "➔ Step 7: Decoded valid User profile response"]);
      await sleep(300);

      setActiveIndex(7);
      markPassed(7);
      await sleep(300);
      setLogs((prev) => [...prev, "✅ 401 Recovered seamlessly! Call site received user without noticing auth hop"]);
    } else if (type === "retry") {
      setActiveIndex(0);
      markPassed(0);
      await sleep(300);

      setActiveIndex(3);
      markPassed(1);
      markPassed(2);
      markPassed(3);
      setLogs((prev) => [...prev, "➔ Initial call to server returned HTTP 503 Service Unavailable"]);
      await sleep(400);

      setActiveIndex(4);
      markPassed(4);
      setLogs((prev) => [...prev, "⏳ RetryEngine: Detected 503. Applying Exponential Backoff + Jitter (delay 250ms)..."]);
      await sleep(600);

      setLogs((prev) => [...prev, "🔁 Attempt 2: Re-executing request via URLSessionTransport..."]);
      await sleep(400);

      setActiveIndex(5);
      markPassed(5);
      await sleep(300);

      setActiveIndex(6);
      markPassed(6);
      await sleep(300);

      setActiveIndex(7);
      markPassed(7);
      await sleep(300);
      setLogs((prev) => [...prev, "✅ Second attempt succeeded with HTTP 200 OK!"]);
    } else if (type === "drop") {
      setActiveIndex(0);
      markPassed(0);
      await sleep(300);

      setActiveIndex(3);
      markPassed(1);
      markPassed(2);
      markPassed(3);
      setLogs((prev) => [...prev, "📡 Network connection dropped (NWPathMonitor: .unsatisfied)"]);
      await sleep(500);

      setLogs((prev) => [...prev, "⏸️ NetworkClient paused awaiting PathNetworkMonitor.connectionRestored()..."]);
      await sleep(800);

      setLogs((prev) => [...prev, "📶 Connectivity Restored (NWPath: .satisfied(.wifi))! Resuming request..."]);
      await sleep(400);

      setActiveIndex(5);
      markPassed(4);
      markPassed(5);
      await sleep(300);

      setActiveIndex(6);
      markPassed(6);
      await sleep(300);

      setActiveIndex(7);
      markPassed(7);
      await sleep(300);
      setLogs((prev) => [...prev, "✅ Request recovered after network reconnection!"]);
    } else if (type === "upload") {
      // 1. Endpoint
      setActiveIndex(0);
      markPassed(0);
      setLogs((prev) => [...prev, "➔ Step 1: UploadMediaEndpoint configured with MultipartFormData (Boundary: SwiftNetworkKit-Boundary-491)"]);
      await sleep(350);

      // 2. Interceptor
      setActiveIndex(1);
      markPassed(1);
      setLogs((prev) => [...prev, "➔ Step 2: RequestInterceptors attached Content-Type: multipart/form-data & Content-Length: 480,219,300 (480 MB)"]);
      await sleep(350);

      // 3. Token
      setActiveIndex(2);
      markPassed(2);
      setLogs((prev) => [...prev, "➔ Step 3: TokenManager injected Bearer auth header from Keychain"]);
      await sleep(350);

      // 4. Transport Stream
      setActiveIndex(3);
      markPassed(3);
      setLogs((prev) => [...prev, "➔ Step 4: DiskUploadStream initialized with zero RAM memory footprint (Streaming from disk tempfile)..."]);
      await sleep(300);
      setLogs((prev) => [...prev, "📤 Uploading: [████░░░░░░░░░░░░] 25% (120 MB streamed / 48 MB/s)"]);
      await sleep(300);
      setLogs((prev) => [...prev, "📤 Uploading: [█████████░░░░░░░] 60% (288 MB streamed / 52 MB/s)"]);
      await sleep(300);
      setLogs((prev) => [...prev, "📤 Uploading: [████████████████] 100% (480 MB complete)"]);
      await sleep(350);

      // 5. Retry
      setActiveIndex(4);
      markPassed(4);
      setLogs((prev) => [...prev, "➔ Step 5: RetryEngine verified idempotency token tx_upload_8891"]);
      await sleep(300);

      // 6. Response Interceptors
      setActiveIndex(5);
      markPassed(5);
      setLogs((prev) => [...prev, "➔ Step 6: Server confirmed HTTP 201 Created (ETag: 7f8a920b)"]);
      await sleep(300);

      // 7. Decode
      setActiveIndex(6);
      markPassed(6);
      setLogs((prev) => [...prev, "➔ Step 7: Decoded UploadReceipt struct (URL: https://cdn.myapp.com/raw/4k_video.mov)"]);
      await sleep(300);

      // 8. Metrics
      setActiveIndex(7);
      markPassed(7);
      await sleep(300);
      setLogs((prev) => [...prev, "✅ 480 MB File uploaded successfully with 0 MB memory leak!"]);
    } else if (type === "download") {
      // 1. Endpoint
      setActiveIndex(0);
      markPassed(0);
      setLogs((prev) => [...prev, "➔ Step 1: DownloadAssetEndpoint constructed for /v1/models/ai-core.bin (128 MB)"]);
      await sleep(350);

      // 2. Interceptor
      setActiveIndex(1);
      markPassed(1);
      setLogs((prev) => [...prev, "➔ Step 2: Injected Range header: bytes=0- & Accept-Encoding: gzip, br"]);
      await sleep(350);

      // 3. Token
      setActiveIndex(2);
      markPassed(2);
      setLogs((prev) => [...prev, "➔ Step 3: TokenManager verified session credentials"]);
      await sleep(350);

      // 4. Transport Stream
      setActiveIndex(3);
      markPassed(3);
      setLogs((prev) => [...prev, "➔ Step 4: URLSessionDownloadTask streaming raw chunks to disk sandbox..."]);
      await sleep(300);
      setLogs((prev) => [...prev, "📥 Downloading: [████░░░░░░░░░░░░] 25% (32 MB / 84 MB/s)"]);
      await sleep(300);
      setLogs((prev) => [...prev, "📥 Downloading: [███████████░░░░░] 75% (96 MB / 92 MB/s)"]);
      await sleep(300);
      setLogs((prev) => [...prev, "📥 Downloading: [████████████████] 100% (128 MB complete)"]);
      await sleep(350);

      // 5. Retry
      setActiveIndex(4);
      markPassed(4);
      setLogs((prev) => [...prev, "➔ Step 5: Resume token verified without network disconnects"]);
      await sleep(300);

      // 6. Response Interceptors
      setActiveIndex(5);
      markPassed(5);
      setLogs((prev) => [...prev, "➔ Step 6: SHA-256 Checksum verified: 8f2b7a90... (Integrity Valid)"]);
      await sleep(300);

      // 7. Destination Move
      setActiveIndex(6);
      markPassed(6);
      setLogs((prev) => [...prev, "➔ Step 7: Atomically moved temp file to Library/Caches/ai-core.bin"]);
      await sleep(300);

      // 8. Metrics
      setActiveIndex(7);
      markPassed(7);
      await sleep(300);
      setLogs((prev) => [...prev, "✅ 128 MB Asset downloaded in 1.4s (91.4 MB/s throughput)!"]);
    }

    setIsRunning(false);
  };

  return (
    <section id="pipeline" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20 text-xs font-semibold mb-3 font-mono">
          <Activity className="w-3.5 h-3.5" /> ARCHITECTURE SIMULATOR
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Visual Request Lifecycle & Pipeline
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Step through how SwiftNetworkKit processes requests across actors, interceptors, secure token caches, SSL trust evaluators, and decoding pipelines.
        </p>
      </div>

      {/* Scenarios (6 Realistic Scenarios including Upload & Download) */}
      <div className="flex flex-wrap items-center justify-center gap-2.5 mb-10">
        <button
          onClick={() => runScenario("success")}
          disabled={isRunning}
          className="px-3.5 py-2 rounded-xl glass-panel hover:border-emerald-500/50 text-xs font-semibold text-emerald-600 dark:text-emerald-400 flex items-center gap-2 transition-all cursor-pointer shadow-sm bg-white dark:bg-slate-900/60"
        >
          <CheckCircle className="w-4 h-4" />
          <span>Standard 200 OK</span>
        </button>

        <button
          onClick={() => runScenario("upload")}
          disabled={isRunning}
          className="px-3.5 py-2 rounded-xl glass-panel hover:border-indigo-500/50 text-xs font-semibold text-indigo-600 dark:text-indigo-400 flex items-center gap-2 transition-all cursor-pointer shadow-sm bg-white dark:bg-slate-900/60"
        >
          <UploadCloud className="w-4 h-4" />
          <span>RFC 7578 Streaming Disk Upload</span>
        </button>

        <button
          onClick={() => runScenario("download")}
          disabled={isRunning}
          className="px-3.5 py-2 rounded-xl glass-panel hover:border-teal-500/50 text-xs font-semibold text-teal-600 dark:text-teal-400 flex items-center gap-2 transition-all cursor-pointer shadow-sm bg-white dark:bg-slate-900/60"
        >
          <DownloadCloud className="w-4 h-4" />
          <span>Chunked Asset Download</span>
        </button>

        <button
          onClick={() => runScenario("auth")}
          disabled={isRunning}
          className="px-3.5 py-2 rounded-xl glass-panel hover:border-sky-500/50 text-xs font-semibold text-sky-600 dark:text-sky-400 flex items-center gap-2 transition-all cursor-pointer shadow-sm bg-white dark:bg-slate-900/60"
        >
          <RefreshCw className="w-4 h-4" />
          <span>401 Token Refresh</span>
        </button>

        <button
          onClick={() => runScenario("retry")}
          disabled={isRunning}
          className="px-3.5 py-2 rounded-xl glass-panel hover:border-amber-500/50 text-xs font-semibold text-amber-600 dark:text-amber-400 flex items-center gap-2 transition-all cursor-pointer shadow-sm bg-white dark:bg-slate-900/60"
        >
          <Timer className="w-4 h-4" />
          <span>503 Jitter Backoff</span>
        </button>

        <button
          onClick={() => runScenario("drop")}
          disabled={isRunning}
          className="px-3.5 py-2 rounded-xl glass-panel hover:border-rose-500/50 text-xs font-semibold text-rose-600 dark:text-rose-400 flex items-center gap-2 transition-all cursor-pointer shadow-sm bg-white dark:bg-slate-900/60"
        >
          <WifiOff className="w-4 h-4" />
          <span>Network Drop & Reconnect</span>
        </button>
      </div>

      {/* 8 Stage Nodes Grid */}
      <div className="grid grid-cols-2 sm:grid-cols-4 lg:grid-cols-8 gap-3 mb-8">
        {PIPELINE_STEPS.map((step, idx) => {
          const isCurrentRunning = isRunning && idx === activeIndex;
          const isPassed = passedSteps.includes(idx);
          const isSelected = idx === activeIndex;

          return (
            <button
              key={step.id}
              onClick={() => setActiveIndex(idx)}
              className={`p-3 rounded-xl glass-panel text-left flex flex-col justify-between cursor-pointer border transition-all duration-300 min-h-[110px] ${
                isCurrentRunning
                  ? "border-sky-500 dark:border-sky-400 scale-105 shadow-md shadow-sky-500/20 bg-sky-50/80 dark:bg-sky-950/40 ring-2 ring-sky-500/30"
                  : isPassed
                  ? isSelected
                    ? "border-emerald-500 scale-105 bg-emerald-50/80 dark:bg-emerald-950/40 ring-2 ring-emerald-500/30 shadow-md shadow-emerald-500/20"
                    : "border-emerald-500/60 dark:border-emerald-500/50 bg-emerald-50/60 dark:bg-emerald-950/30 shadow-sm shadow-emerald-500/10 text-emerald-900 dark:text-emerald-200"
                  : isSelected
                  ? "border-sky-500 dark:border-sky-400 scale-105 shadow-md shadow-sky-500/20 bg-sky-50/50 dark:bg-sky-950/30"
                  : "border-slate-200 dark:border-white/5 opacity-80 hover:opacity-100 bg-white dark:bg-slate-900/60"
              }`}
            >
              <div className="flex items-center justify-between mb-2">
                <span
                  className={`text-xs font-mono font-bold px-2 py-0.5 rounded border transition-colors ${
                    isCurrentRunning
                      ? "bg-sky-500 text-white border-sky-400"
                      : isPassed
                      ? "bg-emerald-500/20 text-emerald-600 dark:text-emerald-400 border-emerald-500/40 font-bold"
                      : isSelected
                      ? "bg-sky-500 text-white border-sky-400"
                      : "bg-slate-100 dark:bg-slate-800 text-slate-500 dark:text-slate-400 border-slate-200 dark:border-slate-700"
                  }`}
                >
                  0{idx + 1}
                </span>
                
                {isPassed && !isCurrentRunning ? (
                  <Check className="w-3.5 h-3.5 text-emerald-500 shrink-0 stroke-[2.5]" />
                ) : (
                  <span
                    className={`w-2 h-2 rounded-full transition-colors ${
                      isCurrentRunning
                        ? "bg-sky-500 dark:bg-sky-400 animate-pulse ring-4 ring-sky-500/20"
                        : "bg-slate-300 dark:bg-slate-600"
                    }`}
                  />
                )}
              </div>

              <div>
                <h4
                  className={`text-xs font-bold leading-tight mb-1 ${
                    isPassed && !isCurrentRunning
                      ? "text-emerald-800 dark:text-emerald-200"
                      : isCurrentRunning || isSelected
                      ? "text-sky-700 dark:text-sky-300"
                      : "text-slate-900 dark:text-slate-100"
                  }`}
                >
                  {step.title}
                </h4>
                <p className="text-[10px] text-slate-500 dark:text-slate-400 leading-tight">
                  {step.subtitle}
                </p>
              </div>
            </button>
          );
        })}
      </div>

      {/* Inspector Details & Live Console */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-6">
        <div className="lg:col-span-6 glass-panel p-6 bg-white/90 dark:bg-slate-900/70 shadow-lg">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-200 dark:border-white/10">
            <div>
              <h3 className="font-bold text-lg text-slate-900 dark:text-white">
                0{activeIndex + 1}. {activeStep.title}
              </h3>
              <p className="text-xs text-sky-600 dark:text-sky-400 font-mono mt-0.5">
                {activeStep.subtitle}
              </p>
            </div>
            <span
              className={`text-xs font-mono px-2.5 py-1 rounded font-semibold border ${
                passedSteps.includes(activeIndex) && !isRunning
                  ? "bg-emerald-500/10 text-emerald-700 dark:text-emerald-400 border-emerald-500/30"
                  : "bg-sky-500/10 text-sky-700 dark:text-sky-400 border-sky-500/20"
              }`}
            >
              {passedSteps.includes(activeIndex) && !isRunning ? "Passed & Validated" : activeStep.status}
            </span>
          </div>
          <p className="text-sm text-slate-600 dark:text-slate-300 mb-6 leading-relaxed">{activeStep.desc}</p>

          <h4 className="text-xs font-semibold text-slate-500 dark:text-slate-400 uppercase tracking-wider font-mono mb-2">
            Request / State Metadata
          </h4>
          <div className="space-y-1 rounded-xl bg-slate-950 p-4 border border-slate-800 font-mono text-xs text-slate-200">
            {Object.entries(activeStep.headers).map(([k, v]) => (
              <div key={k} className="flex items-center justify-between text-xs py-1 border-b border-slate-800 last:border-0">
                <span className="text-sky-400">{k}:</span>
                <span className="text-slate-300 truncate max-w-[220px]">{v}</span>
              </div>
            ))}
          </div>
        </div>

        {/* Live Console Log Stream */}
        <div className="lg:col-span-6 glass-panel p-6 flex flex-col bg-white/90 dark:bg-slate-900/70 shadow-lg">
          <div className="flex items-center justify-between mb-4 pb-3 border-b border-slate-200 dark:border-white/10">
            <div className="flex items-center gap-2">
              <Terminal className="w-4 h-4 text-orange-600 dark:text-orange-400" />
              <span className="text-sm font-semibold font-mono text-slate-900 dark:text-slate-200">Execution Log Stream</span>
            </div>
            <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-100 dark:bg-slate-800 text-slate-600 dark:text-slate-400 font-semibold">
              ConsoleNetworkLogger
            </span>
          </div>

          <div className="flex-1 min-h-[220px] max-h-[260px] overflow-y-auto bg-slate-950 rounded-xl p-4 border border-slate-800 space-y-1.5 font-mono text-xs leading-relaxed text-slate-300">
            {logs.map((log, i) => (
              <div key={i}>{log}</div>
            ))}
          </div>
        </div>
      </div>
    </section>
  );
}
