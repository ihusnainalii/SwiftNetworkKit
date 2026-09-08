"use client";

import React, { useState } from "react";
import { ShieldAlert, Play, RotateCcw, XCircle, CheckCircle2, FileText, Lock } from "lucide-react";

export function ConcurrencyVisualizer() {
  const [isRunning, setIsRunning] = useState(false);
  const [naivePos, setNaivePos] = useState({ r1: "5%", r2: "5%", r3: "5%" });
  const [snkPos, setSnkPos] = useState({ r1: "5%", r2: "5%", r3: "5%" });
  const [naiveClass, setNaiveClass] = useState("bg-slate-800 text-slate-200");
  const [snkClass, setSnkClass] = useState("bg-slate-800 text-slate-200");
  const [naiveStatus, setNaiveStatus] = useState("Click 'Run Concurrency Test' to test 3 simultaneous 401s");
  const [snkStatus, setSnkStatus] = useState("Click 'Run Concurrency Test' to test SwiftNetworkKit Actor Queueing");

  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  const runSimulation = async () => {
    if (isRunning) return;
    setIsRunning(true);

    setNaiveStatus("3 concurrent requests hit 401 simultaneously...");
    setSnkStatus("3 concurrent requests hit 401 simultaneously...");

    setNaivePos({ r1: "30%", r2: "30%", r3: "30%" });
    setSnkPos({ r1: "30%", r2: "30%", r3: "30%" });

    await sleep(600);

    setNaiveStatus("⚠️ Race Condition! 3 separate Refresh Token calls fired! Token rotated 3x -> Invalidation!");
    setNaiveClass("bg-rose-600 text-white");
    setNaivePos({ r1: "60%", r2: "60%", r3: "60%" });

    setSnkStatus("🛡️ Actor TokenManager detects flight: Req 1 executes refresh, Req 2 & 3 queue in Actor suspension");
    setSnkClass("bg-sky-600 text-white");
    setSnkPos({ r1: "60%", r2: "45%", r3: "45%" });

    await sleep(1200);

    setNaiveStatus("❌ 2 out of 3 requests crashed with 401 SessionExpired (Token Mismatch)");
    setNaiveClass("bg-rose-700 text-white");
    setNaivePos({ r1: "90%", r2: "90%", r3: "90%" });

    setSnkStatus("✅ Single-flight refresh complete! All 3 requests replayed with new token (100% Success)");
    setSnkClass("bg-emerald-600 text-white");
    setSnkPos({ r1: "90%", r2: "90%", r3: "90%" });

    setIsRunning(false);
  };

  const resetSimulation = () => {
    setNaivePos({ r1: "5%", r2: "5%", r3: "5%" });
    setSnkPos({ r1: "5%", r2: "5%", r3: "5%" });
    setNaiveClass("bg-slate-800 text-slate-200");
    setSnkClass("bg-slate-800 text-slate-200");
    setNaiveStatus("Click 'Run Concurrency Test' to test 3 simultaneous 401s");
    setSnkStatus("Click 'Run Concurrency Test' to test SwiftNetworkKit Actor Queueing");
  };

  return (
    <section id="concurrency" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20 text-xs font-semibold mb-3 font-mono">
          <ShieldAlert className="w-3.5 h-3.5" /> THREAD SAFETY & ACTORS
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Single-Flight Token Refresh vs. Race Conditions
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          What happens when 3 concurrent requests all receive a 401 Unauthorized at the exact same millisecond? See how SwiftNetworkKit's Swift Actor architecture prevents token stampedes.
        </p>
      </div>

      {/* Controls */}
      <div className="flex items-center justify-center gap-4 mb-8">
        <button
          onClick={runSimulation}
          disabled={isRunning}
          className="px-6 py-3 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-semibold text-sm flex items-center gap-2 shadow-lg shadow-purple-600/30 transition-all cursor-pointer"
        >
          <Play className="w-4 h-4" />
          <span>Run Concurrency Test</span>
        </button>
        <button
          onClick={resetSimulation}
          className="px-5 py-3 rounded-xl glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white font-semibold text-sm transition-all cursor-pointer flex items-center gap-2 shadow-sm bg-white dark:bg-slate-900/60"
        >
          <RotateCcw className="w-4 h-4" />
          <span>Reset</span>
        </button>
      </div>

      {/* Comparison Lanes */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-8">
        {/* Naive Lane */}
        <div className="glass-panel p-6 border-rose-500/30 bg-white/90 dark:bg-slate-900/70 shadow-lg">
          <div className="flex items-center justify-between pb-3 mb-4 border-b border-rose-500/20">
            <h3 className="font-bold text-rose-600 dark:text-rose-400 flex items-center gap-2">
              <XCircle className="w-5 h-5" />
              Traditional Client (Race Conditions)
            </h3>
            <span className="text-xs font-mono text-rose-700 dark:text-rose-400 bg-rose-500/10 px-2 py-0.5 rounded font-bold">Unsafe</span>
          </div>

          <div className="space-y-4 mb-6">
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${naiveClass}`}
                style={{ left: naivePos.r1 }}
              >
                <FileText className="w-3.5 h-3.5" /> Req A (/feed)
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${naiveClass}`}
                style={{ left: naivePos.r2 }}
              >
                <FileText className="w-3.5 h-3.5" /> Req B (/profile)
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${naiveClass}`}
                style={{ left: naivePos.r3 }}
              >
                <FileText className="w-3.5 h-3.5" /> Req C (/notifications)
              </div>
            </div>
          </div>

          <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs text-slate-200 min-h-[50px] flex items-center">
            {naiveStatus}
          </div>
        </div>

        {/* SwiftNetworkKit Actor Lane */}
        <div className="glass-panel p-6 border-emerald-500/30 bg-white/90 dark:bg-slate-900/70 shadow-lg">
          <div className="flex items-center justify-between pb-3 mb-4 border-b border-emerald-500/20">
            <h3 className="font-bold text-emerald-600 dark:text-emerald-400 flex items-center gap-2">
              <CheckCircle2 className="w-5 h-5" />
              SwiftNetworkKit (Actor TokenManager)
            </h3>
            <span className="text-xs font-mono text-emerald-700 dark:text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded font-bold">Single-Flight</span>
          </div>

          <div className="space-y-4 mb-6">
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${snkClass}`}
                style={{ left: snkPos.r1 }}
              >
                <Lock className="w-3.5 h-3.5" /> Req A (/feed)
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${snkClass}`}
                style={{ left: snkPos.r2 }}
              >
                <Lock className="w-3.5 h-3.5" /> Req B (/profile)
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${snkClass}`}
                style={{ left: snkPos.r3 }}
              >
                <Lock className="w-3.5 h-3.5" /> Req C (/notifications)
              </div>
            </div>
          </div>

          <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs text-emerald-300 min-h-[50px] flex items-center">
            {snkStatus}
          </div>
        </div>
      </div>
    </section>
  );
}
