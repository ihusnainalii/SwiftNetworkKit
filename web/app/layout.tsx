import type { Metadata } from "next";
import "./globals.css";
import { ThemeProvider } from "@/components/ThemeProvider";

export const metadata: Metadata = {
  title: "SwiftNetworkKit - High-Performance Protocol-Oriented Networking for Swift 6",
  description: "A composable, protocol-oriented networking layer for Swift. Zero external dependencies. Swift 6 strict concurrency safe for iOS, macOS, tvOS, watchOS, and visionOS.",
  openGraph: {
    title: "SwiftNetworkKit - Swift 6 Networking Engine",
    description: "Zero dependencies. Actor-isolated token refresh. SPKI SSL pinning. Intelligent jitter retry. Built for Swift 6.",
    url: "https://github.com/ihusnainalii/SwiftNetworkKit",
    type: "website",
  },
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="en" className="light" suppressHydrationWarning>
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap" rel="stylesheet" />
      </head>
      <body className="font-sans relative bg-slate-50 dark:bg-[#07090e] text-slate-900 dark:text-slate-100" suppressHydrationWarning>
        <ThemeProvider>
          {children}
        </ThemeProvider>
      </body>
    </html>
  );
}
