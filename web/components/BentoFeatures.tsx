"use client";

import React from "react";
import { Layers, Cpu, ShieldCheck, Repeat, UploadCloud, EyeOff, Wifi } from "lucide-react";

export function BentoFeatures() {
  const features = [
    {
      icon: Cpu,
      color: "text-orange-600 dark:text-orange-400 bg-orange-500/10 border-orange-500/20",
      title: "Swift 6 Strict Concurrency",
      desc: "Fully annotated with Sendable conformances and thread-safe actor boundaries. Guarantees 0 data races under the Swift 6 compiler.",
    },
    {
      icon: ShieldCheck,
      color: "text-sky-600 dark:text-sky-400 bg-sky-500/10 border-sky-500/20",
      title: "SPKI Public Key Pinning",
      desc: "Zero third-party security libs. Pins raw Subject Public Key Info SHA-256 hashes or bundled certificates with native Trust evaluation.",
    },
    {
      icon: Repeat,
      color: "text-amber-600 dark:text-amber-400 bg-amber-500/10 border-amber-500/20",
      title: "Jitter & Rate Limit Engine",
      desc: "Full and equal jitter prevent thundering herds on microservices. Automatically parses and respects HTTP Retry-After headers.",
    },
    {
      icon: UploadCloud,
      color: "text-purple-600 dark:text-purple-400 bg-purple-500/10 border-purple-500/20",
      title: "RFC 7578 Multipart Uploads",
      desc: "Streams gigabyte-sized files straight from local disk into the transport socket with byte-level progress reporting (ProgressEvent).",
    },
    {
      icon: EyeOff,
      color: "text-emerald-600 dark:text-emerald-400 bg-emerald-500/10 border-emerald-500/20",
      title: "Redacting Privacy Logger",
      desc: "Logs cURL commands and status codes without ever leaking Bearer tokens, passwords, or sensitive API keys in the Xcode debug console.",
    },
    {
      icon: Wifi,
      color: "text-indigo-600 dark:text-indigo-400 bg-indigo-500/10 border-indigo-500/20",
      title: "AsyncStream Reachability",
      desc: "Native PathNetworkMonitor wraps Network framework. Yields statusUpdates() and connectionRestored() AsyncStreams.",
    },
  ];

  return (
    <section id="features" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 text-xs font-semibold mb-3 font-mono">
          <Layers className="w-3.5 h-3.5" /> FULL ARCHITECTURE
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
            <div key={idx} className="glass-panel p-6 bg-white/90 dark:bg-slate-900/70 shadow-lg">
              <div className={`w-12 h-12 rounded-xl border flex items-center justify-center mb-5 ${feat.color}`}>
                <Icon className="w-6 h-6" />
              </div>
              <h3 className="text-lg font-bold text-slate-900 dark:text-white mb-2">{feat.title}</h3>
              <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed">{feat.desc}</p>
            </div>
          );
        })}
      </div>
    </section>
  );
}
