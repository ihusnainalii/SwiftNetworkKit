"use client";

import React, { useState, useEffect, useRef } from "react";
import {
  Zap,
  Sun,
  Moon,
  Github,
  Star,
  Menu,
  X,
  ChevronDown,
  Cpu,
  Activity,
  Code2,
  GitBranch,
  Layers,
  Scale,
  BookOpen,
  Compass,
  DownloadCloud,
  Sparkles,
  TrendingUp
} from "lucide-react";
import { useTheme } from "./ThemeProvider";

interface DropdownItem {
  id: string;
  title: string;
  desc: string;
  href: string;
  badge?: string;
}

function NavIcon({ id, className = "w-4 h-4" }: { id: string; className?: string }) {
  switch (id) {
    case "pipeline":
      return <Activity className={className} />;
    case "playground":
      return <Code2 className={className} />;
    case "concurrency":
      return <GitBranch className={className} />;
    case "graphs":
      return <TrendingUp className={className} />;
    case "metrics":
      return <Zap className={className} />;
    case "milestones":
      return <Cpu className={className} />;
    case "features":
      return <Layers className={className} />;
    case "compare":
      return <Scale className={className} />;
    case "api":
      return <BookOpen className={className} />;
    case "roadmap":
      return <Compass className={className} />;
    case "install":
      return <DownloadCloud className={className} />;
    default:
      return <Sparkles className={className} />;
  }
}

const INTERACTIVE_LABS: DropdownItem[] = [
  {
    id: "pipeline",
    title: "Pipeline Simulator",
    desc: "Step-by-step interactive 8-stage request lifecycle",
    href: "#pipeline",
  },
  {
    id: "playground",
    title: "Code Playground",
    desc: "Live visual endpoint builder with Swift 6 codegen",
    href: "#playground",
  },
  {
    id: "concurrency",
    title: "Concurrency Visualizer",
    desc: "Single-flight token refresh actor & priority queueing",
    href: "#concurrency",
  },
  {
    id: "graphs",
    title: "Caching & Concurrency Graphs",
    desc: "Two-tier latency waterfall, jitter curves & ROI calculator",
    href: "#graphs",
    badge: "Interactive",
  },
  {
    id: "metrics",
    title: "Telemetry & Metrics",
    desc: "Microsecond timing & request observability breakdown",
    href: "#metrics",
  },
];

const ARCHITECTURE_ITEMS: DropdownItem[] = [
  {
    id: "milestones",
    title: "15 Engine Subsystems",
    desc: "Decoupled, actor-isolated architectural modules",
    href: "#architecture",
    badge: "Blueprint",
  },
  {
    id: "features",
    title: "12 Core Capabilities",
    desc: "Zero-dependency bento feature matrix",
    href: "#features",
  },
  {
    id: "compare",
    title: "Library Comparison",
    desc: "SwiftNetworkKit vs Alamofire vs URLSession",
    href: "#compare",
    badge: "VS",
  },
];

const DOCS_ITEMS: DropdownItem[] = [
  {
    id: "api",
    title: "API Reference",
    desc: "Searchable type dictionary & Swift 6 signatures",
    href: "#api-reference",
    badge: "25+ Types",
  },
  {
    id: "roadmap",
    title: "Roadmap to 1.0.0",
    desc: "Release velocity, API freeze & candidate features",
    href: "#roadmap",
  },
  {
    id: "install",
    title: "SPM Installation",
    desc: "Swift Package Manager & Xcode setup guide",
    href: "#installation",
  },
];

export function Navbar() {
  const { theme, toggleTheme } = useTheme();
  const [mobileMenuOpen, setMobileMenuOpen] = useState(false);
  const [activeDropdown, setActiveDropdown] = useState<string | null>(null);
  const dropdownRef = useRef<HTMLDivElement>(null);

  // Close dropdown on outside click
  useEffect(() => {
    function handleClickOutside(event: MouseEvent) {
      if (dropdownRef.current && !dropdownRef.current.contains(event.target as Node)) {
        setActiveDropdown(null);
      }
    }
    document.addEventListener("mousedown", handleClickOutside);
    return () => document.removeEventListener("mousedown", handleClickOutside);
  }, []);

  return (
    <header className="fixed top-0 left-0 right-0 z-50 glass-nav transition-all duration-300">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 h-20 flex items-center justify-between" ref={dropdownRef}>
        
        {/* Brand Logo */}
        <a href="#" className="flex items-center gap-3 group shrink-0">
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
        <nav className="hidden lg:flex items-center gap-1 text-sm font-medium text-slate-700 dark:text-slate-200">
          
          {/* Interactive Labs Dropdown */}
          <div
            className="relative"
            onMouseEnter={() => setActiveDropdown("labs")}
            onMouseLeave={() => setActiveDropdown(null)}
          >
            <button
              onClick={() => setActiveDropdown(activeDropdown === "labs" ? null : "labs")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold uppercase tracking-wider transition-all cursor-pointer ${
                activeDropdown === "labs"
                  ? "bg-slate-200/70 dark:bg-white/10 text-orange-600 dark:text-orange-400"
                  : "hover:bg-slate-100 dark:hover:bg-white/5 hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              <span>Interactive Labs</span>
              <ChevronDown className={`w-3.5 h-3.5 transition-transform duration-200 ${activeDropdown === "labs" ? "rotate-180" : ""}`} />
            </button>

            {activeDropdown === "labs" && (
              <div className="absolute top-full left-0 mt-2 w-96 p-3 rounded-2xl bg-white/95 dark:bg-slate-900/95 backdrop-blur-2xl border border-slate-200 dark:border-white/10 shadow-2xl space-y-1 animate-in fade-in slide-in-from-top-2 duration-200">
                {INTERACTIVE_LABS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    onClick={() => setActiveDropdown(null)}
                    className="flex items-start gap-3 p-3 rounded-xl hover:bg-slate-100 dark:hover:bg-white/5 transition-colors group"
                  >
                    <div className="w-8 h-8 rounded-lg bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 flex items-center justify-center shrink-0 mt-0.5 group-hover:scale-105 transition-transform">
                      <NavIcon id={item.id} className="w-4 h-4" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-xs font-bold text-slate-900 dark:text-slate-100 group-hover:text-orange-600 dark:group-hover:text-orange-400 transition-colors leading-snug">
                          {item.title}
                        </span>
                        {item.badge && (
                          <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-orange-500/15 text-orange-600 dark:text-orange-400 font-bold shrink-0">
                            {item.badge}
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-mono mt-0.5 leading-relaxed">
                        {item.desc}
                      </span>
                    </div>
                  </a>
                ))}
              </div>
            )}
          </div>

          {/* Architecture & Specs Dropdown */}
          <div
            className="relative"
            onMouseEnter={() => setActiveDropdown("arch")}
            onMouseLeave={() => setActiveDropdown(null)}
          >
            <button
              onClick={() => setActiveDropdown(activeDropdown === "arch" ? null : "arch")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold uppercase tracking-wider transition-all cursor-pointer ${
                activeDropdown === "arch"
                  ? "bg-slate-200/70 dark:bg-white/10 text-orange-600 dark:text-orange-400"
                  : "hover:bg-slate-100 dark:hover:bg-white/5 hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              <span>Architecture</span>
              <ChevronDown className={`w-3.5 h-3.5 transition-transform duration-200 ${activeDropdown === "arch" ? "rotate-180" : ""}`} />
            </button>

            {activeDropdown === "arch" && (
              <div className="absolute top-full left-0 mt-2 w-96 p-3 rounded-2xl bg-white/95 dark:bg-slate-900/95 backdrop-blur-2xl border border-slate-200 dark:border-white/10 shadow-2xl space-y-1 animate-in fade-in slide-in-from-top-2 duration-200">
                {ARCHITECTURE_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    onClick={() => setActiveDropdown(null)}
                    className="flex items-start gap-3 p-3 rounded-xl hover:bg-slate-100 dark:hover:bg-white/5 transition-colors group"
                  >
                    <div className="w-8 h-8 rounded-lg bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20 flex items-center justify-center shrink-0 mt-0.5 group-hover:scale-105 transition-transform">
                      <NavIcon id={item.id} className="w-4 h-4" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-xs font-bold text-slate-900 dark:text-slate-100 group-hover:text-sky-600 dark:group-hover:text-sky-400 transition-colors leading-snug">
                          {item.title}
                        </span>
                        {item.badge && (
                          <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-orange-500/15 text-orange-600 dark:text-orange-400 font-bold shrink-0">
                            {item.badge}
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-mono mt-0.5 leading-relaxed">
                        {item.desc}
                      </span>
                    </div>
                  </a>
                ))}
              </div>
            )}
          </div>

          {/* Documentation Dropdown */}
          <div
            className="relative"
            onMouseEnter={() => setActiveDropdown("docs")}
            onMouseLeave={() => setActiveDropdown(null)}
          >
            <button
              onClick={() => setActiveDropdown(activeDropdown === "docs" ? null : "docs")}
              className={`flex items-center gap-1.5 px-3.5 py-2 rounded-xl text-xs font-semibold uppercase tracking-wider transition-all cursor-pointer ${
                activeDropdown === "docs"
                  ? "bg-slate-200/70 dark:bg-white/10 text-orange-600 dark:text-orange-400"
                  : "hover:bg-slate-100 dark:hover:bg-white/5 hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              <span>Documentation</span>
              <ChevronDown className={`w-3.5 h-3.5 transition-transform duration-200 ${activeDropdown === "docs" ? "rotate-180" : ""}`} />
            </button>

            {activeDropdown === "docs" && (
              <div className="absolute top-full left-0 mt-2 w-96 p-3 rounded-2xl bg-white/95 dark:bg-slate-900/95 backdrop-blur-2xl border border-slate-200 dark:border-white/10 shadow-2xl space-y-1 animate-in fade-in slide-in-from-top-2 duration-200">
                {DOCS_ITEMS.map((item) => (
                  <a
                    key={item.id}
                    href={item.href}
                    onClick={() => setActiveDropdown(null)}
                    className="flex items-start gap-3 p-3 rounded-xl hover:bg-slate-100 dark:hover:bg-white/5 transition-colors group"
                  >
                    <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 flex items-center justify-center shrink-0 mt-0.5 group-hover:scale-105 transition-transform">
                      <NavIcon id={item.id} className="w-4 h-4" />
                    </div>
                    <div className="flex-1">
                      <div className="flex items-center justify-between gap-2">
                        <span className="text-xs font-bold text-slate-900 dark:text-slate-100 group-hover:text-emerald-600 dark:group-hover:text-emerald-400 transition-colors leading-snug">
                          {item.title}
                        </span>
                        {item.badge && (
                          <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 font-bold shrink-0">
                            {item.badge}
                          </span>
                        )}
                      </div>
                      <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-mono mt-0.5 leading-relaxed">
                        {item.desc}
                      </span>
                    </div>
                  </a>
                ))}
              </div>
            )}
          </div>

          {/* Direct Highlight Link to Architecture Blueprint */}
          <a
            href="#architecture"
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 hover:bg-orange-500/20 transition-all font-mono ml-2"
          >
            <Cpu className="w-3.5 h-3.5" />
            <span>Architecture</span>
          </a>

          {/* Direct Highlight Link to API Reference */}
          <a
            href="#api-reference"
            className="flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-semibold bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20 hover:bg-sky-500/20 transition-all font-mono"
          >
            <BookOpen className="w-3.5 h-3.5" />
            <span>API Docs</span>
          </a>
        </nav>

        {/* Right Actions */}
        <div className="flex items-center gap-3 shrink-0">
          <button
            onClick={toggleTheme}
            className="p-2.5 rounded-xl glass-panel hover:border-orange-500/40 text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white transition-all cursor-pointer shadow-sm"
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
            className="flex items-center gap-2 px-3.5 py-2 rounded-xl glass-panel hover:border-orange-500/40 text-xs sm:text-sm font-semibold text-slate-700 dark:text-slate-200 hover:text-slate-900 dark:hover:text-white transition-all shadow-sm"
          >
            <Github className="w-4 h-4" />
            <span className="hidden sm:inline">GitHub</span>
            <Star className="w-3.5 h-3.5 text-amber-500 fill-amber-500" />
          </a>

          {/* Mobile Menu Toggle Button */}
          <button
            onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
            className="lg:hidden p-2.5 rounded-xl glass-panel text-slate-700 dark:text-slate-300 hover:text-slate-900 dark:hover:text-white cursor-pointer"
            aria-label="Open Navigation Menu"
          >
            {mobileMenuOpen ? <X className="w-5 h-5" /> : <Menu className="w-5 h-5" />}
          </button>
        </div>
      </div>

      {/* Mobile Menu Drawer */}
      {mobileMenuOpen && (
        <div className="lg:hidden glass-panel mx-4 mb-4 p-5 rounded-2xl border border-slate-200 dark:border-white/10 bg-white/95 dark:bg-slate-900/95 backdrop-blur-2xl shadow-2xl max-h-[80vh] overflow-y-auto custom-scrollbar animate-in fade-in slide-in-from-top-4 duration-200 space-y-5">
          
          {/* Group: Interactive Labs */}
          <div>
            <span className="text-[10px] font-mono font-bold text-orange-600 dark:text-orange-400 uppercase tracking-wider block mb-2.5">
              Interactive Labs
            </span>
            <div className="grid grid-cols-1 gap-2.5">
              {INTERACTIVE_LABS.map((item) => (
                <a
                  key={item.id}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-start gap-3 p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-white/5"
                >
                  <div className="w-8 h-8 rounded-lg bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 flex items-center justify-center shrink-0 mt-0.5">
                    <NavIcon id={item.id} className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-bold text-slate-900 dark:text-slate-100">
                        {item.title}
                      </span>
                      {item.badge && (
                        <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-orange-500/15 text-orange-600 dark:text-orange-400 font-bold shrink-0">
                          {item.badge}
                        </span>
                      )}
                    </div>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-mono mt-0.5 leading-relaxed">
                      {item.desc}
                    </span>
                  </div>
                </a>
              ))}
            </div>
          </div>

          {/* Group: Architecture */}
          <div>
            <span className="text-[10px] font-mono font-bold text-sky-600 dark:text-sky-400 uppercase tracking-wider block mb-2.5">
              Engine Architecture &amp; Subsystems
            </span>
            <div className="grid grid-cols-1 gap-2.5">
              {ARCHITECTURE_ITEMS.map((item) => (
                <a
                  key={item.id}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-start gap-3 p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-white/5"
                >
                  <div className="w-8 h-8 rounded-lg bg-sky-500/10 text-sky-600 dark:text-sky-400 border border-sky-500/20 flex items-center justify-center shrink-0 mt-0.5">
                    <NavIcon id={item.id} className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-bold text-slate-900 dark:text-slate-100">
                        {item.title}
                      </span>
                      {item.badge && (
                        <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-orange-500/15 text-orange-600 dark:text-orange-400 font-bold shrink-0">
                          {item.badge}
                        </span>
                      )}
                    </div>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-mono mt-0.5 leading-relaxed">
                      {item.desc}
                    </span>
                  </div>
                </a>
              ))}
            </div>
          </div>

          {/* Group: Documentation */}
          <div>
            <span className="text-[10px] font-mono font-bold text-emerald-600 dark:text-emerald-400 uppercase tracking-wider block mb-2.5">
              Documentation &amp; Guides
            </span>
            <div className="grid grid-cols-1 gap-2.5">
              {DOCS_ITEMS.map((item) => (
                <a
                  key={item.id}
                  href={item.href}
                  onClick={() => setMobileMenuOpen(false)}
                  className="flex items-start gap-3 p-3 rounded-xl bg-slate-50 dark:bg-slate-800/60 border border-slate-200 dark:border-white/5"
                >
                  <div className="w-8 h-8 rounded-lg bg-emerald-500/10 text-emerald-600 dark:text-emerald-400 border border-emerald-500/20 flex items-center justify-center shrink-0 mt-0.5">
                    <NavIcon id={item.id} className="w-4 h-4" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <div className="flex items-center justify-between gap-2">
                      <span className="text-xs font-bold text-slate-900 dark:text-slate-100">
                        {item.title}
                      </span>
                      {item.badge && (
                        <span className="text-[9px] font-mono px-1.5 py-0.5 rounded bg-emerald-500/15 text-emerald-600 dark:text-emerald-400 font-bold shrink-0">
                          {item.badge}
                        </span>
                      )}
                    </div>
                    <span className="text-[11px] text-slate-500 dark:text-slate-400 block font-mono mt-0.5 leading-relaxed">
                      {item.desc}
                    </span>
                  </div>
                </a>
              ))}
            </div>
          </div>
        </div>
      )}
    </header>
  );
}
