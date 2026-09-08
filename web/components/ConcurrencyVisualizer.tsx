"use client";

import React, { useState } from "react";
import {
  ShieldAlert,
  Play,
  RotateCcw,
  XCircle,
  CheckCircle2,
  FileText,
  Lock,
  GitMerge,
  ListFilter,
  Zap
} from "lucide-react";

type ConcurrencyMode = "token_refresh" | "deduplication" | "priority_queue";

export function ConcurrencyVisualizer() {
  const [mode, setMode] = useState<ConcurrencyMode>("token_refresh");
  const [isRunning, setIsRunning] = useState(false);
  const [naivePos, setNaivePos] = useState({ r1: "5%", r2: "5%", r3: "5%" });
  const [snkPos, setSnkPos] = useState({ r1: "5%", r2: "5%", r3: "5%" });
  const [naiveClass, setNaiveClass] = useState("bg-slate-800 text-slate-200");
  const [snkClass, setSnkClass] = useState("bg-slate-800 text-slate-200");
  const [naiveStatus, setNaiveStatus] = useState("Click 'Run Simulation' to test race conditions");
  const [snkStatus, setSnkStatus] = useState("Click 'Run Simulation' to test SwiftNetworkKit Actor safety");

  const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  const runSimulation = async () => {
    if (isRunning) return;
    setIsRunning(true);

    if (mode === "token_refresh") {
      setNaiveStatus("3 concurrent requests hit 401 Unauthorized simultaneously...");
      setSnkStatus("3 concurrent requests hit 401 Unauthorized simultaneously...");

      setNaivePos({ r1: "30%", r2: "30%", r3: "30%" });
      setSnkPos({ r1: "30%", r2: "30%", r3: "30%" });

      await sleep(600);

      setNaiveStatus("⚠️ Race Condition! 3 separate Refresh Token calls fired! Token rotated 3x -> Invalidation!");
      setNaiveClass("bg-rose-600 text-white");
      setNaivePos({ r1: "60%", r2: "60%", r3: "60%" });

      setSnkStatus("🛡️ Actor TokenManager: Req A executes single-flight refresh; Req B & C suspend in actor queue");
      setSnkClass("bg-sky-600 text-white");
      setSnkPos({ r1: "60%", r2: "45%", r3: "45%" });

      await sleep(1200);

      setNaiveStatus("❌ 2 out of 3 requests crashed with 401 SessionExpired (Token Mismatch)");
      setNaiveClass("bg-rose-700 text-white");
      setNaivePos({ r1: "90%", r2: "90%", r3: "90%" });

      setSnkStatus("✅ Single-flight refresh complete! All 3 requests replayed with new token (100% Success, 0 Data Races)");
      setSnkClass("bg-emerald-600 text-white");
      setSnkPos({ r1: "90%", r2: "90%", r3: "90%" });
    } else if (mode === "deduplication") {
      setNaiveStatus("3 independent views invoke client.request(GetProfileEndpoint()) at the exact same moment...");
      setSnkStatus("3 independent views invoke client.request(GetProfileEndpoint()) at the exact same moment...");

      setNaivePos({ r1: "30%", r2: "30%", r3: "30%" });
      setSnkPos({ r1: "30%", r2: "30%", r3: "30%" });

      await sleep(600);

      setNaiveStatus("⚠️ Traditional client: 3 identical network sockets opened, 3x cellular data consumed");
      setNaiveClass("bg-amber-600 text-white");
      setNaivePos({ r1: "65%", r2: "65%", r3: "65%" });

      setSnkStatus("🔀 RequestDeduplicator Actor: Detected identical in-flight GET flight. Coalescing View 2 & 3 onto View 1's Task...");
      setSnkClass("bg-sky-600 text-white");
      setSnkPos({ r1: "65%", r2: "65%", r3: "65%" });

      await sleep(1000);

      setNaiveStatus("📊 3 full HTTP roundtrips completed (3x server load, 3x bandwidth)");
      setNaiveClass("bg-amber-700 text-white");
      setNaivePos({ r1: "90%", r2: "90%", r3: "90%" });

      setSnkStatus("✅ Deduplication complete: 1 single network flight served all 3 views simultaneously!");
      setSnkClass("bg-emerald-600 text-white");
      setSnkPos({ r1: "90%", r2: "90%", r3: "90%" });
    } else if (mode === "priority_queue") {
      setNaiveStatus("Queue full. Req A (.low telemetry), Req B (.low logs), Req C (.urgent checkout)...");
      setSnkStatus("Queue full. Req A (.low telemetry), Req B (.low logs), Req C (.urgent checkout)...");

      setNaivePos({ r1: "35%", r2: "35%", r3: "35%" });
      setSnkPos({ r1: "35%", r2: "35%", r3: "35%" });

      await sleep(600);

      setNaiveStatus("⏳ Traditional FIFO: Urgent Checkout is stuck waiting behind background telemetry logs...");
      setNaiveClass("bg-rose-600 text-white");
      setNaivePos({ r1: "65%", r2: "50%", r3: "35%" });

      setSnkStatus("⚡ PriorityTaskQueue Actor: Elevated Req C (.urgent) to head of execution queue!");
      setSnkClass("bg-sky-600 text-white");
      setSnkPos({ r1: "45%", r2: "35%", r3: "75%" });

      await sleep(1000);

      setNaiveStatus("❌ User waited 850ms for checkout due to head-of-line queue blocking");
      setNaiveClass("bg-rose-700 text-white");
      setNaivePos({ r1: "90%", r2: "70%", r3: "50%" });

      setSnkStatus("✅ Urgent checkout executed in 38ms! Background telemetry resumed cleanly in parallel.");
      setSnkClass("bg-emerald-600 text-white");
      setSnkPos({ r1: "70%", r2: "50%", r3: "90%" });
    }

    setIsRunning(false);
  };

  const resetSimulation = () => {
    setNaivePos({ r1: "5%", r2: "5%", r3: "5%" });
    setSnkPos({ r1: "5%", r2: "5%", r3: "5%" });
    setNaiveClass("bg-slate-800 text-slate-200");
    setSnkClass("bg-slate-800 text-slate-200");
    setNaiveStatus("Click 'Run Simulation' to test race conditions");
    setSnkStatus("Click 'Run Simulation' to test SwiftNetworkKit Actor safety");
  };

  return (
    <section id="concurrency" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-12">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-purple-500/10 text-purple-600 dark:text-purple-400 border border-purple-500/20 text-xs font-semibold mb-3 font-mono">
          <ShieldAlert className="w-3.5 h-3.5" /> THREAD SAFETY & ACTORS
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Concurrency Visualizer & Actor Isolation
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Explore how SwiftNetworkKit's 13 isolated Swift actors eliminate data races, prevent token stampedes, coalesce in-flight duplicates, and schedule high-priority requests.
        </p>
      </div>

      {/* Mode Switcher */}
      <div className="flex flex-wrap items-center justify-center gap-2 mb-8">
        <button
          onClick={() => {
            setMode("token_refresh");
            resetSimulation();
          }}
          className={`px-3.5 py-2 rounded-xl text-xs font-semibold flex items-center gap-2 cursor-pointer transition-all ${
            mode === "token_refresh"
              ? "bg-purple-600 text-white shadow-md shadow-purple-600/20"
              : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 border border-slate-200 dark:border-transparent"
          }`}
        >
          <Lock className="w-4 h-4" />
          <span>401 Single-Flight Token Refresh</span>
        </button>

        <button
          onClick={() => {
            setMode("deduplication");
            resetSimulation();
          }}
          className={`px-3.5 py-2 rounded-xl text-xs font-semibold flex items-center gap-2 cursor-pointer transition-all ${
            mode === "deduplication"
              ? "bg-purple-600 text-white shadow-md shadow-purple-600/20"
              : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 border border-slate-200 dark:border-transparent"
          }`}
        >
          <GitMerge className="w-4 h-4" />
          <span>In-Flight Request Deduplication</span>
        </button>

        <button
          onClick={() => {
            setMode("priority_queue");
            resetSimulation();
          }}
          className={`px-3.5 py-2 rounded-xl text-xs font-semibold flex items-center gap-2 cursor-pointer transition-all ${
            mode === "priority_queue"
              ? "bg-purple-600 text-white shadow-md shadow-purple-600/20"
              : "glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white bg-white dark:bg-slate-900/60 border border-slate-200 dark:border-transparent"
          }`}
        >
          <Zap className="w-4 h-4" />
          <span>Priority Task Scheduling</span>
        </button>
      </div>

      {/* Controls */}
      <div className="flex items-center justify-center gap-4 mb-8">
        <button
          onClick={runSimulation}
          disabled={isRunning}
          className="px-6 py-3 rounded-xl bg-purple-600 hover:bg-purple-500 text-white font-semibold text-sm flex items-center gap-2 shadow-lg shadow-purple-600/30 transition-all cursor-pointer disabled:opacity-50"
        >
          <Play className="w-4 h-4" />
          <span>Run Simulation</span>
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
              Traditional Concurrency (Race Conditions)
            </h3>
            <span className="text-xs font-mono text-rose-700 dark:text-rose-400 bg-rose-500/10 px-2 py-0.5 rounded font-bold">Unsafe</span>
          </div>

          <div className="space-y-4 mb-6">
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${naiveClass}`}
                style={{ left: naivePos.r1 }}
              >
                <FileText className="w-3.5 h-3.5" />
                {mode === "priority_queue" ? "Req A (.low)" : "Req A (/feed)"}
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${naiveClass}`}
                style={{ left: naivePos.r2 }}
              >
                <FileText className="w-3.5 h-3.5" />
                {mode === "priority_queue" ? "Req B (.low)" : "Req B (/profile)"}
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${naiveClass}`}
                style={{ left: naivePos.r3 }}
              >
                <FileText className="w-3.5 h-3.5" />
                {mode === "priority_queue" ? "Req C (.urgent)" : "Req C (/notifications)"}
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
              SwiftNetworkKit (13 Isolated Actors)
            </h3>
            <span className="text-xs font-mono text-emerald-700 dark:text-emerald-400 bg-emerald-500/10 px-2 py-0.5 rounded font-bold">
              {mode === "token_refresh" ? "TokenManager" : mode === "deduplication" ? "RequestDeduplicator" : "PriorityQueue"}
            </span>
          </div>

          <div className="space-y-4 mb-6">
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${snkClass}`}
                style={{ left: snkPos.r1 }}
              >
                <Lock className="w-3.5 h-3.5" />
                {mode === "priority_queue" ? "Req A (.low)" : "Req A (/feed)"}
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${snkClass}`}
                style={{ left: snkPos.r2 }}
              >
                <Lock className="w-3.5 h-3.5" />
                {mode === "priority_queue" ? "Req B (.low)" : "Req B (/profile)"}
              </div>
            </div>
            <div className="concurrency-lane h-12 relative bg-slate-100 dark:bg-slate-950 rounded-xl border border-slate-200 dark:border-white/5 overflow-hidden">
              <div
                className={`concurrency-packet absolute top-1/2 -translate-y-1/2 h-7 px-3 rounded-full flex items-center gap-1.5 text-xs font-semibold transition-all duration-500 ${snkClass}`}
                style={{ left: snkPos.r3 }}
              >
                <Lock className="w-3.5 h-3.5" />
                {mode === "priority_queue" ? "Req C (.urgent)" : "Req C (/notifications)"}
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
