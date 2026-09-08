"use client";

import React, { useState } from "react";
import { Package, Copy, Check } from "lucide-react";

export function SpmInstall() {
  const [tab, setTab] = useState<"xcode" | "manifest" | "cli">("xcode");
  const [copied, setCopied] = useState(false);

  const manifestSnippet = `// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MyProject",
    platforms: [.iOS(.v16), .macOS(.v13), .visionOS(.v1)],
    dependencies: [
        .package(url: "https://github.com/ihusnainalii/SwiftNetworkKit.git", from: "1.0.0")
    ],
    targets: [
        .target(
            name: "MyProject",
            dependencies: [
                .product(name: "SwiftNetworkKit", package: "SwiftNetworkKit")
            ]
        )
    ]
)`;

  const cliSnippet = `# Live tour hitting JSONPlaceholder API
swift run NetworkKitDemo

# Offline test suite (single-flight 401 refresh walkthrough)
swift run NetworkKitDemo --offline`;

  const copyContent = () => {
    let text = "https://github.com/ihusnainalii/SwiftNetworkKit";
    if (tab === "manifest") text = manifestSnippet;
    if (tab === "cli") text = cliSnippet;
    navigator.clipboard.writeText(text);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  return (
    <section id="installation" className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 py-20 border-t border-slate-200 dark:border-white/5">
      <div className="text-center max-w-3xl mx-auto mb-16">
        <div className="inline-flex items-center gap-2 px-3 py-1 rounded-full bg-orange-500/10 text-orange-600 dark:text-orange-400 border border-orange-500/20 text-xs font-semibold mb-3 font-mono">
          <Package className="w-3.5 h-3.5" /> SWIFT PACKAGE MANAGER
        </div>
        <h2 className="text-3xl sm:text-4xl font-extrabold tracking-tight mb-4 text-slate-900 dark:text-white">
          Add to Your Project in Seconds
        </h2>
        <p className="text-slate-600 dark:text-slate-400 text-base leading-relaxed">
          Install SwiftNetworkKit via Xcode Package Manager, <code className="text-xs text-orange-600 dark:text-orange-300 font-bold">Package.swift</code> manifest, or Swift CLI.
        </p>
      </div>

      <div className="max-w-4xl mx-auto glass-panel p-8 bg-white/90 dark:bg-slate-900/70 shadow-xl">
        <div className="flex items-center justify-between pb-4 mb-6 border-b border-slate-200 dark:border-white/10">
          <div className="flex items-center gap-6 text-sm font-semibold text-slate-500 dark:text-slate-400">
            <button
              onClick={() => setTab("xcode")}
              className={`pb-2 cursor-pointer transition-colors ${
                tab === "xcode" ? "text-orange-600 dark:text-sky-400 border-b-2 border-orange-600 dark:border-sky-400 font-bold" : "hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              Xcode GUI
            </button>
            <button
              onClick={() => setTab("manifest")}
              className={`pb-2 cursor-pointer transition-colors ${
                tab === "manifest" ? "text-orange-600 dark:text-sky-400 border-b-2 border-orange-600 dark:border-sky-400 font-bold" : "hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              Package.swift Manifest
            </button>
            <button
              onClick={() => setTab("cli")}
              className={`pb-2 cursor-pointer transition-colors ${
                tab === "cli" ? "text-orange-600 dark:text-sky-400 border-b-2 border-orange-600 dark:border-sky-400 font-bold" : "hover:text-slate-900 dark:hover:text-white"
              }`}
            >
              Swift CLI & Demo
            </button>
          </div>

          <button
            onClick={copyContent}
            className="px-3 py-1.5 rounded-lg bg-slate-100 hover:bg-slate-200 dark:bg-slate-800 dark:hover:bg-slate-700 text-xs font-mono text-slate-700 dark:text-slate-300 flex items-center gap-1.5 cursor-pointer border border-slate-200 dark:border-transparent"
          >
            {copied ? <Check className="w-3.5 h-3.5 text-emerald-600 dark:text-emerald-400" /> : <Copy className="w-3.5 h-3.5" />}
            <span>{copied ? "Copied!" : "Copy Snippet"}</span>
          </button>
        </div>

        {tab === "xcode" && (
          <div className="space-y-4">
            <ol className="list-decimal list-inside text-sm text-slate-700 dark:text-slate-300 space-y-2 leading-relaxed">
              <li>In Xcode, select <strong className="text-slate-900 dark:text-white">File ➔ Add Package Dependencies...</strong></li>
              <li>Paste the repository URL into the search bar:</li>
            </ol>
            <div className="p-3 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs text-sky-400">
              <code>https://github.com/ihusnainalii/SwiftNetworkKit</code>
            </div>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              Select Dependency Rule: <strong className="text-slate-800 dark:text-slate-200">Up to Next Major Version</strong> starting at <code className="text-orange-600 dark:text-orange-300 font-bold">1.0.0</code>.
            </p>
          </div>
        )}

        {tab === "manifest" && (
          <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs overflow-x-auto text-sky-300">
            <pre className="whitespace-pre font-mono leading-relaxed"><code>{manifestSnippet}</code></pre>
          </div>
        )}

        {tab === "cli" && (
          <div className="space-y-4">
            <p className="text-sm text-slate-700 dark:text-slate-300">Run the live interactive CLI tour directly in your terminal:</p>
            <div className="p-4 rounded-xl bg-slate-950 border border-slate-800 font-mono text-xs overflow-x-auto text-sky-300">
              <pre className="whitespace-pre font-mono leading-relaxed"><code>{cliSnippet}</code></pre>
            </div>
          </div>
        )}
      </div>
    </section>
  );
}
