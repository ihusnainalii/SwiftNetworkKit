"use client";

import React, { useState } from "react";
import { Zap, Sun, Moon, Github, Star, Menu, X } from "lucide-react";
import { useTheme } from "./ThemeProvider";

export function Navbar() {
  const { theme, toggleTheme } = useTheme();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 glass-nav transition-all duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between">
        
        {/* Brand Logo */}
        <a href="#" className="flex items-center gap-3 group">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-tr from-orange-600 via-swift to-amber-500 flex items-center justify-center shadow-lg shadow-orange-500/20 group-hover:scale-105 transition-transform">
            <Zap className="w-5 h-5 text-white" />
          </div>
          <div className="flex flex-col">
            <span className="font-bold text-lg tracking-tight text-slate-900 dark:text-white flex items-center gap-1.5">
              SwiftNetworkKit
              <span className="text-[10px] font-mono px-1.5 py-0.5 rounded bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 font-bold">
                v0.1.0
              </span>
            </span>
            <span className="text-[11px] text-slate-500 dark:text-slate-400 font-mono">Swift 6 Strict Concurrency</span>
          </div>
        </a>

        {/* Desktop Navigation Links */}
        <nav className="hidden md:flex items-center gap-5 text-sm font-medium text-slate-600 dark:text-slate-300">
          <a href="#pipeline" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">Pipeline</a>
          <a href="#playground" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">Playground</a>
          <a href="#concurrency" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">Concurrency</a>
          <a href="#compare" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors flex items-center gap-1">
            <span>Compare</span>
            <span className="text-[9px] px-1.5 py-0.5 rounded bg-orange-500/15 text-orange-600 dark:text-orange-400 font-mono font-bold">VS</span>
          </a>
          <a href="#milestones" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors flex items-center gap-1">
            <span>14 Milestones</span>
            <span className="text-[9px] px-1.5 py-0.5 rounded bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 font-mono font-bold">M0-M14</span>
          </a>
          <a href="#features" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">Modules</a>
          <a href="#api-reference" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">API Docs</a>
          <a href="#roadmap" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">Roadmap</a>
          <a href="#installation" className="hover:text-orange-600 dark:hover:text-sky-400 transition-colors">Install</a>
        </nav>

        {/* Right Actions */}
        <div className="flex items-center gap-3">
          <button
            onClick={toggleTheme}
            className="p-2.5 rounded-xl glass-panel hover:border-orange-500/40 text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition-all cursor-pointer"
            title="Toggle Light / Dark Mode"
            aria-label="Toggle Theme"
          >
            {theme === "light" ? (
              <Moon className="w-4 h-4 text-slate-700 hover:text-slate-900" />
            ) : (
              <Sun className="w-4 h-4 text-amber-400" />
            )}
          </button>

          <a
            href="https://github.com/ihusnainalii/SwiftNetworkKit"
            target="_blank"
            rel="noopener noreferrer"
            className="flex items-center gap-2 px-4 py-2 rounded-xl glass-panel hover:border-orange-500/40 text-sm font-semibold text-slate-700 dark:text-slate-200 hover:text-slate-900 dark:hover:text-white transition-all"
          >
            <Github className="w-4 h-4" />
            <span className="hidden sm:inline">GitHub</span>
            <Star className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
          </a>

          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="md:hidden p-2 rounded-lg glass-panel text-slate-700 dark:text-slate-300"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu */}
      {mobileMenuOpen && (
        <div className="md:hidden glass-panel mx-4 mb-4 p-4 flex flex-col gap-3">
          <a href="#pipeline" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">Request Pipeline</a>
          <a href="#playground" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">Code Builder & Playground</a>
          <a href="#concurrency" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">Concurrency Visualizer</a>
          <a href="#compare" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1 font-semibold text-orange-600 dark:text-orange-400">Library Comparison (VS)</a>
          <a href="#milestones" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1 font-semibold text-emerald-600 dark:text-emerald-400">14 Milestones (M0-M14)</a>
          <a href="#features" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">Features Bento</a>
          <a href="#api-reference" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">API Reference</a>
          <a href="#roadmap" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">Roadmap to 1.0.0</a>
          <a href="#installation" onClick={() => setMobileMenuOpen(false)} className="text-sm text-slate-700 dark:text-slate-300 hover:text-orange-600 dark:hover:text-sky-400 py-1">Installation</a>
        </div>
      )}
    </header>
  );
}
