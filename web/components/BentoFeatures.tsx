"use client";

import React from "react";
import {
  Layers,
  Cpu,
  ShieldCheck,
  Repeat,
  UploadCloud,
  EyeOff,
  Wifi,
  Key,
  HardDrive,
  Database,
  ListOrdered,
  Sparkles,
  TestTube2
} from "lucide-react";

export function BentoFeatures() {
  const features = [
    {
      icon: Cpu,
      color: "text-orange-600 dark:text-orange-400 bg-orange-500/10 border-orange-500/20",
      title: "Swift 6 Strict Concurrency",
      desc: "Fully annotated with Sendable conformances and thread-safe actor boundaries. Guarantees 0 data races under the Swift 6 compiler.",
    },
    {
      icon: Key,
      color: "text-sky-600 dark:text-sky-400 bg-sky-500/10 border-sky-500/20",
      title: "Single-Flight 401 & OAuth PKCE",
      desc: "Actor-isolated token refresh ensures 10 simultaneous 401s trigger exactly one refresh. Full RFC 7636 PKCE Authorization Code flow built-in.",
    },
    {
      icon: ShieldCheck,
      color: "text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 border-emerald-500/20",
      title: "SPKI Public Key Pinning",
      desc: "Zero third-party security libs. Pins raw Subject Public Key Info SHA-256 hashes or bundled certificates with native Trust evaluation.",
    },
    {
      icon: HardDrive,
      color: "text-indigo-600 dark:text-indigo-400 bg-indigo-500/10 border-indigo-500/20",
      title: "Persisted Offline Replay Queue",
      desc: "Opt-in per endpoint. Queues requests when offline into encrypted FileOfflineStore and automatically replays FIFO upon network restoration.",
    },
    {
      icon: Database,
      color: "text-teal-600 dark:text-teal-400 bg-teal-500/10 border-teal-500/20",
      title: "Memory & Disk HTTP Caching",
      desc: "DiskCacheStore & MemoryCacheStore with ETag / 304 revalidation, stale-while-revalidate, and network-failure fallback.",
    },
    {
      icon: Repeat,
      color: "text-amber-600 dark:text-amber-400 bg-amber-500/10 border-amber-500/20",
      title: "Jitter & Rate Limit Engine",
      desc: "Full and equal jitter prevent thundering herds on microservices. Automatically parses and respects HTTP 429 / 503 Retry-After headers.",
    },
    {
      icon: UploadCloud,
      color: "text-purple-600 dark:text-purple-400 bg-purple-500/10 border-purple-500/20",
      title: "RFC 7578 Multipart Disk Uploads",
      desc: "Streams gigabyte-sized files straight from local disk into the transport socket with real-time byte progress reporting (ProgressEvent).",
    },
    {
      icon: ListOrdered,
      color: "text-pink-600 dark:text-pink-400 bg-pink-500/10 border-pink-500/20",
      title: "Pagination as AsyncSequence",
      desc: "PaginatedEndpoint yields AsyncThrowingStream pages automatically. Includes client.zip and client.batch for parallel execution.",
    },
    {
      icon: Sparkles,
      color: "text-blue-600 dark:text-blue-400 bg-blue-500/10 border-blue-500/20",
      title: "SwiftUI @Observable & Combine",
      desc: "NetworkResource<Value> and Paged<Item> state containers for iOS 17+ Observation, plus optional Combine publishers (#if canImport).",
    },
    {
      icon: EyeOff,
      color: "text-rose-600 dark:text-rose-400 bg-rose-500/10 border-rose-500/20",
      title: "Redacting Privacy Logger",
      desc: "Logs cURL commands and status codes without ever leaking Bearer tokens, cookies, or sensitive API keys in the Xcode debug console.",
    },
    {
      icon: Wifi,
      color: "text-cyan-600 dark:text-cyan-400 bg-cyan-500/10 border-cyan-500/20",
      title: "NWPathMonitor Reachability",
      desc: "PathNetworkMonitor wraps Network framework, yielding statusUpdates() and connectionRestored() AsyncStreams.",
    },
    {
      icon: TestTube2,
      color: "text-lime-600 dark:text-lime-400 bg-lime-500/10 border-lime-500/20",
      title: "Shipped Test Doubles",
      desc: "MockNetworkTransport (FIFO queue & pattern stubs), URLProtocolStub, TestClock (fast-forward time), and CapturingLogger ship directly in the library.",
    },
  ];

  return (
    <section id="features" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 text-xs font-semibold mb-3 font-mono">
          <Layers className="w-3.5 h-3.5" /> COMPLETE ARCHITECTURE
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Enterprise Features Built For Scale
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Engineered with clean architectural separation, zero third-party dependencies, and native Swift 6 concurrency primitives.
        </p>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
        {features.map((feat, idx) => {
          const Icon = feat.icon;
          return (
            <div key={idx} className="glass-panel p-6 bg-white/90 dark:bg-slate-900/70 shadow-lg rounded-2xl flex flex-col justify-between">
              <div>
                <div className={`w-12 h-12 rounded-xl border flex items-center justify-center mb-5 ${feat.color}`}>
                  <Icon className="w-6 h-6" />
                </div>
                <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-2">{feat.title}</h3>
                <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">{feat.desc}</p>
              </div>
            </div>
          );
        })}
      </div>
    </section>
  );
}
