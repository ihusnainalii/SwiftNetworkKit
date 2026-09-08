"use client";

import React, { useState, useEffect } from "react";
import { Check } from "lucide-react";

export function MetricsDashboard() {
  const [totalRequests, setTotalRequests] = useState(12480);
  const [p95, setP95] = useState("38.4");
  const [errRate, setErrRate] = useState("0.11");
  const [throughput, setThroughput] = useState(28);

  useEffect(() => {
    let reqs = 12480;
    let errors = 14;

    const interval = setInterval(() => {
      const increment = Math.floor(Math.random() * 8) + 3;
      reqs += increment;
      if (Math.random() > 0.85) errors += 1;

      setTotalRequests(reqs);
      setP95((34 + Math.random() * 7).toFixed(1));
      setErrRate(((errors / reqs) * 100).toFixed(2));
      setThroughput(Math.floor(increment * 3.6));
    }, 1600);

    return () => clearInterval(interval);
  }, []);

  return (
    <section className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="glass-panel p-8 relative overflow-hidden bg-white/90 dark:bg-slate-900/70 shadow-xl">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-8 items-center">
          <div className="lg:col-span-5">
            <span className="text-xs font-mono px-3 py-1 rounded-full bg-sky-500/10 text-sky-700 dark:text-sky-400 border border-sky-500/20 font-bold mb-4 inline-block">
              IN-MEMORY OBSERVABILITY
            </span>
            <h3 className="text-2xl sm:text-3xl font-bold text-slate-900 dark:text-white mb-3">
              Real-Time Metrics & Latency Histogram
            </h3>
            <p className="text-sm text-slate-600 dark:text-slate-400 leading-relaxed mb-6">
              Pluggable <code className="text-xs font-bold text-sky-600 dark:text-sky-300">NetworkMetrics</code> sink captures exact P50, P90, P95 durations, status code distributions, and throughput with zero performance penalty.
            </p>
            <div className="flex items-center gap-4 text-xs font-mono text-slate-600 dark:text-slate-400 font-semibold">
              <span className="flex items-center gap-1">
                <Check className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" /> Zero Overhead
              </span>
              <span className="flex items-center gap-1">
                <Check className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" /> Thread-Safe
              </span>
            </div>
          </div>

          <div className="lg:col-span-7 grid grid-cols-2 sm:grid-cols-4 gap-4">
            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-center shadow-md">
              <span className="text-[11px] font-mono text-slate-400 block mb-1">TOTAL REQUESTS</span>
              <span className="text-2xl font-bold font-mono text-sky-400">
                {totalRequests.toLocaleString()}
              </span>
            </div>

            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-center shadow-md">
              <span className="text-[11px] font-mono text-slate-400 block mb-1">P95 LATENCY</span>
              <span className="text-2xl font-bold font-mono text-emerald-400">{p95}ms</span>
            </div>

            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-center shadow-md">
              <span className="text-[11px] font-mono text-slate-400 block mb-1">ERROR RATE</span>
              <span className="text-2xl font-bold font-mono text-amber-400">{errRate}%</span>
            </div>

            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 text-center shadow-md">
              <span className="text-[11px] font-mono text-slate-400 block mb-1">THROUGHPUT</span>
              <span className="text-2xl font-bold font-mono text-purple-400">{throughput} req/s</span>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
