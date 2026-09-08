"use client";

import React, { useState } from "react";
import { Terminal, Copy, Check, PlayCircle, GitCompare, ShieldCheck, Lock, RefreshCw, Compass } from "lucide-react";

export function Hero() {
  const [copied, setCopied] = useState(false);
  const [codeCopied, setCodeCopied] = useState(false);

  const spmUrl = "https://github.com/ihusnainalii/SwiftNetworkKit";

  const copyUrl = () => {
    navigator.clipboard.writeText(spmUrl);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const codeSample = `// 1. Configure once with Keychain Token Storage
let client = NetworkClient(
    configuration: NetworkConfiguration(
        baseURL: "https://api.example.com",
        tokenStorage: KeychainTokenStorage(service: "com.acme.app")
    ),
    refresh: { storage in
        try await authService.refreshToken(storage.refreshToken())
    },
    onSessionExpired: { await AppRouter.logout() }
)

// 2. Strongly Typed Protocol-Oriented Endpoint
struct GetProfile: Endpoint {
    typealias Response = User
    var path: String { "/me" }
    var authentication: AuthRequirement { .required }
}

// 3. Concurrency-Safe Async Execution
let user: User = try await client.request(GetProfile())`;

  const copyCode = () => {
    navigator.clipboard.writeText(codeSample);
    setCodeCopied(true);
    setTimeout(() => setCodeCopied(false), 2000);
  };

  return (
    <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 pt-12 pb-24">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-12 items-center">
        
        {/* Left Column */}
        <div className="lg:col-span-7 flex flex-col items-start">
          
          <div className="inline-flex items-center gap-2 px-3.5 py-1.5 rounded-full glass-panel border border-orange-500/30 text-xs font-semibold text-orange-600 dark:text-orange-400 mb-6 shadow-sm">
            <span className="flex h-2 w-2 rounded-full bg-orange-500 animate-ping"></span>
            <span>Swift 6 Strict Concurrency • Zero External Dependencies • v0.1.0</span>
          </div>

          <h1 className="text-4xl sm:text-5xl lg:text-6xl font-extrabold tracking-tight leading-[1.15] mb-6 text-slate-900 dark:text-white">
            The <span className="gradient-text-swift">Protocol-Oriented</span><br />
            Networking Engine for Swift.
          </h1>

          <p className="text-lg sm:text-xl text-slate-600 dark:text-slate-400 font-normal leading-relaxed mb-8 max-w-2xl">
            A production-grade, composable Apple-platform networking layer with <strong className="text-slate-900 dark:text-slate-200">Actor-isolated single-flight 401 token refresh</strong>, <strong className="text-slate-900 dark:text-slate-200">zero-dependency SPKI SSL pinning</strong>, OAuth 2.0 PKCE, persisted offline replay queue, and RFC 7578 disk uploads.
          </p>

          {/* SPM Quick Copy Bar */}
          <div className="w-full max-w-xl p-2 rounded-2xl glass-panel border border-slate-200 dark:border-white/10 flex items-center justify-between gap-3 mb-8 shadow-xl bg-white/90 dark:bg-slate-900/70">
            <div className="flex items-center gap-3 pl-3 overflow-hidden">
              <Terminal className="w-4 h-4 text-orange-600 dark:text-sky-400 shrink-0" />
              <code className="text-xs font-mono text-slate-800 dark:text-sky-300 truncate">{spmUrl}</code>
            </div>
            <button
              onClick={copyUrl}
              className="px-4 py-2 rounded-xl bg-orange-600 hover:bg-orange-500 text-white text-xs font-semibold flex items-center gap-1.5 transition-all shrink-0 cursor-pointer shadow-md shadow-orange-600/30"
            >
              {copied ? <Check className="w-3.5 h-3.5 text-white" /> : <Copy className="w-3.5 h-3.5" />}
              <span>{copied ? "Copied!" : "Copy SPM URL"}</span>
            </button>
          </div>

          {/* Compatibility Badges */}
          <div className="flex flex-wrap items-center gap-2 mb-8 text-xs font-mono text-slate-600 dark:text-slate-400">
            <span className="px-2.5 py-1 rounded-lg bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-white/5 shadow-sm">iOS 16+</span>
            <span className="px-2.5 py-1 rounded-lg bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-white/5 shadow-sm">macOS 13+</span>
            <span className="px-2.5 py-1 rounded-lg bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-white/5 shadow-sm">visionOS 1+</span>
            <span className="px-2.5 py-1 rounded-lg bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-white/5 shadow-sm">tvOS 16+</span>
            <span className="px-2.5 py-1 rounded-lg bg-white dark:bg-slate-800/60 border border-slate-200 dark:border-white/5 shadow-sm">watchOS 9+</span>
          </div>

          {/* Action CTAs */}
          <div className="flex flex-wrap items-center gap-4">
            <a
              href="#pipeline"
              className="px-6 py-3.5 rounded-xl bg-gradient-to-r from-orange-600 to-amber-600 hover:from-orange-500 hover:to-amber-500 text-white text-sm font-semibold flex items-center gap-2 shadow-lg shadow-orange-500/25 transition-all"
            >
              <PlayCircle className="w-4 h-4" />
              <span>Interactive Pipeline</span>
            </a>
            <a
              href="#compare"
              className="px-6 py-3.5 rounded-xl glass-panel hover:border-orange-500/40 text-sm font-semibold text-slate-700 dark:text-slate-200 hover:text-slate-900 dark:hover:text-white flex items-center gap-2 transition-all shadow-sm"
            >
              <GitCompare className="w-4 h-4 text-orange-600 dark:text-orange-400" />
              <span>Compare (vs Alamofire/Moya)</span>
            </a>
            <a
              href="#roadmap"
              className="px-6 py-3.5 rounded-xl glass-panel hover:border-sky-500/40 text-sm font-semibold text-slate-700 dark:text-slate-200 hover:text-slate-900 dark:hover:text-white flex items-center gap-2 transition-all shadow-sm"
            >
              <Compass className="w-4 h-4 text-sky-600 dark:text-sky-400" />
              <span>1.0.0 Roadmap</span>
            </a>
          </div>

        </div>

        {/* Right 3D Spatial Code Terminal */}
        <div className="lg:col-span-5">
          <div className="glass-panel p-6 shadow-2xl relative overflow-hidden border border-slate-200 dark:border-white/15 bg-slate-900 text-slate-100 rounded-2xl">
            
            <div className="flex items-center justify-between pb-4 mb-4 border-b border-slate-800">
              <div className="flex items-center gap-2">
                <span className="w-3 h-3 rounded-full bg-rose-500/80"></span>
                <span className="w-3 h-3 rounded-full bg-amber-500/80"></span>
                <span className="w-3 h-3 rounded-full bg-emerald-500/80"></span>
              </div>
              <span className="text-xs font-mono text-slate-300 font-semibold flex items-center gap-1.5">
                <ShieldCheck className="w-3.5 h-3.5 text-emerald-400" />
                Swift 6 Strict Concurrency
              </span>
              <button
                onClick={copyCode}
                className="text-xs text-slate-400 hover:text-white flex items-center gap-1 cursor-pointer"
              >
                {codeCopied ? <Check className="w-3.5 h-3.5 text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
              </button>
            </div>

            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs overflow-x-auto text-sky-300 leading-relaxed">
              <pre className="whitespace-pre font-mono leading-relaxed"><code>{codeSample}</code></pre>
            </div>

            <div className="mt-4 pt-4 border-t border-slate-800 flex items-center justify-between text-[11px] font-mono text-slate-300">
              <span className="text-emerald-400 flex items-center gap-1">
                <Check className="w-3 h-3" /> 0 Data Races
              </span>
              <span className="text-sky-400 flex items-center gap-1">
                <RefreshCw className="w-3 h-3" /> Single-Flight 401
              </span>
              <span className="text-purple-400 flex items-center gap-1">
                <Lock className="w-3 h-3" /> SPKI Pinning
              </span>
            </div>

          </div>
        </div>

      </div>
    </section>
  );
}
