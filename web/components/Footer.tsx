"use client";

import React from "react";
import { Zap, Github } from "lucide-react";

export function Footer() {
  return (
    <footer className="relative z-10 border-t border-slate-200 dark:border-white/10 glass-nav py-12 mt-20">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 flex flex-col sm:flex-row items-center justify-between gap-6">
        <div className="flex items-center gap-3">
          <div className="w-8 h-8 rounded-lg bg-orange-600 flex items-center justify-center text-white shadow-md">
            <Zap className="w-4 h-4" />
          </div>
          <div>
            <span className="font-bold text-sm text-slate-900 dark:text-white">SwiftNetworkKit</span>
            <p className="text-xs text-slate-500">Released under Apache-2.0 License</p>
          </div>
        </div>

        <div className="flex items-center gap-6 text-xs text-slate-600 dark:text-slate-400 font-mono">
          <a
            href="https://github.com/ihusnainalii/SwiftNetworkKit"
            target="_blank"
            rel="noopener noreferrer"
            className="hover:text-slate-900 dark:hover:text-white flex items-center gap-1.5 transition-colors"
          >
            <Github className="w-4 h-4" />
            <span>GitHub</span>
          </a>
          <a href="#compare" className="hover:text-slate-900 dark:hover:text-white transition-colors">Compare</a>
          <a href="#pipeline" className="hover:text-slate-900 dark:hover:text-white transition-colors">Pipeline</a>
          <a href="#playground" className="hover:text-slate-900 dark:hover:text-white transition-colors">Code Builder</a>
          <a href="#api-reference" className="hover:text-slate-900 dark:hover:text-white transition-colors">API Docs</a>
        </div>
      </div>
    </footer>
  );
}
