"use client";

import React from "react";
import { Compass, CheckCircle2, Clock, Sparkles, ArrowRight, ShieldCheck, Terminal } from "lucide-react";

export function RoadmapSection() {
  const currentStatus = [
    { title: "Core & Architecture", status: "Done (v0.1.0)", desc: "Swift 6 strict concurrency, Sendable conformances, protocol-oriented Endpoint." },
    { title: "Authentication & TokenManager", status: "Done (v0.1.0)", desc: "Actor-isolated single-flight 401 token refresh, KeychainTokenStorage, loop guard." },
    { title: "OAuth 2.0 PKCE", status: "Done (v0.1.0)", desc: "RFC 7636 Authorization Code Flow, verifier generation, token exchange handler." },
    { title: "Security & SPKI Pinning", status: "Done (v0.1.0)", desc: "SPKI SHA-256 Public Key Pinning, Certificate pinning, .development discovery mode." },
    { title: "Offline Queue & Caching", status: "Done (v0.1.0)", desc: "Persisted FileOfflineStore, FIFO automatic replay, DiskCacheStore with ETag / 304." },
    { title: "Transfers & Pagination", status: "Done (v0.1.0)", desc: "RFC 7578 multipart disk streaming, PaginatedEndpoint AsyncSequence, batch/zip." },
  ];

  const toward100 = [
    {
      track: "Public API Freeze & Audit",
      target: "v1.0.0 Milestone",
      details: "Audit public vs package access levels; mark stable symbols; encapsulate @_spi test hooks.",
      done: true
    },
    {
      track: "Per-Topic DocC Articles",
      target: "v1.0.0 Milestone",
      details: "Comprehensive Apple DocC reference documentation published to GitHub Pages directly via CI.",
      done: false
    },
    {
      track: "90% Test Coverage Target",
      target: "v1.0.0 Milestone",
      details: "Lift transport delegate coverage via URLProtocolStub suite; ThreadSanitizer & AddressSanitizer matrix.",
      done: false
    },
    {
      track: "Multi-Platform CI Hardening",
      target: "v1.0.0 Milestone",
      details: "Linux (Foundation-only subset), tvOS, watchOS, and visionOS simulator automated test suites.",
      done: false
    }
  ];

  const post100 = [
    "WebSocket & Server-Sent Events (SSE) Endpoint type (AsyncSequence of frames)",
    "GraphQL Helper Layer (Query + Variables to Endpoint with typed errors)",
    "Background URLSession transfer support with app-side completion handler",
    "Response-Body Streaming (client.stream(endpoint) -> AsyncSequence<Data>)",
    "swift-log Bridge (Shipped as standalone product to keep core dependency-free)",
    "Request/Response VCR Fixture Recorder built on URLProtocolStub"
  ];

  return (
    <section id="roadmap" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20 text-xs font-semibold mb-3 font-mono">
          <Compass className="w-3.5 h-3.5" /> RELEASE MILESTONES
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Roadmap to 1.0.0 & Beyond
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Track our release velocity, stabilizing API freeze, and future capabilities planned for SwiftNetworkKit.
        </p>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 mb-12">
        {/* Left Column: Toward 1.0.0 Milestones */}
        <div className="lg:col-span-7 glass-panel p-6 sm:p-8 bg-white/90 dark:bg-slate-900/70 shadow-xl border border-slate-200 dark:border-white/10 rounded-2xl">
          <div className="flex items-center justify-between pb-4 mb-6 border-b border-slate-200 dark:border-white/10">
            <div>
              <h3 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                <ShieldCheck className="w-5 h-5 text-orange-600 dark:text-orange-400" />
                Toward 1.0.0 Stabilization
              </h3>
              <p className="text-xs text-slate-500 font-mono mt-0.5">Current Phase: v0.1.0 Feature Complete</p>
            </div>
            <span className="text-xs font-mono px-2.5 py-1 rounded bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 font-bold">
              In Progress
            </span>
          </div>

          <div className="space-y-4">
            {toward100.map((item, idx) => (
              <div key={idx} className="p-4 rounded-xl bg-slate-50 dark:bg-slate-950/60 border border-slate-200 dark:border-slate-800">
                <div className="flex items-center justify-between mb-1.5">
                  <span className="font-bold text-sm text-slate-900 dark:text-slate-100 flex items-center gap-2">
                    {item.done ? (
                      <CheckCircle2 className="w-4 h-4 text-emerald-500" />
                    ) : (
                      <Clock className="w-4 h-4 text-amber-500" />
                    )}
                    {item.track}
                  </span>
                  <span className="text-[10px] font-mono px-2 py-0.5 rounded bg-slate-200 dark:bg-slate-800 text-slate-700 dark:text-slate-300">
                    {item.target}
                  </span>
                </div>
                <p className="text-xs text-slate-600 dark:text-slate-400 pl-6 leading-relaxed">
                  {item.details}
                </p>
              </div>
            ))}
          </div>
        </div>

        {/* Right Column: Candidate Post-1.0 Features */}
        <div className="lg:col-span-5 glass-panel p-6 sm:p-8 bg-white/90 dark:bg-slate-900/70 shadow-xl border border-slate-200 dark:border-white/10 rounded-2xl flex flex-col justify-between">
          <div>
            <div className="flex items-center justify-between pb-4 mb-6 border-b border-slate-200 dark:border-white/10">
              <div>
                <h3 className="text-xl font-bold text-slate-900 dark:text-white flex items-center gap-2">
                  <Sparkles className="w-5 h-5 text-sky-500" />
                  Post-1.0 Planned Features
                </h3>
                <p className="text-xs text-slate-500 font-mono mt-0.5">Architecture Extensions</p>
              </div>
            </div>

            <ul className="space-y-3">
              {post100.map((feat, idx) => (
                <li key={idx} className="flex items-start gap-2.5 text-xs text-slate-700 dark:text-slate-300 font-medium">
                  <ArrowRight className="w-3.5 h-3.5 text-sky-500 shrink-0 mt-0.5" />
                  <span>{feat}</span>
                </li>
              ))}
            </ul>
          </div>

          <div className="mt-6 pt-4 border-t border-slate-200 dark:border-slate-800 text-xs font-mono text-slate-500 flex items-center justify-between">
            <span>Automated Releases via release-please</span>
            <a href="https://github.com/ihusnainalii/SwiftNetworkKit/blob/main/ROADMAP.md" target="_blank" rel="noreferrer" className="text-sky-600 dark:text-sky-400 hover:underline">
              ROADMAP.md ➔
            </a>
          </div>
        </div>
      </div>
    </section>
  );
}
