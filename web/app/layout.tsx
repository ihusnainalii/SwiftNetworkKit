import type { Metadata, Viewport } from "next";
import "./globals.css";
import { ThemeProvider } from "@/components/ThemeProvider";

export const viewport: Viewport = {
  width: "device-width",
  initialScale: 1,
  maximumScale: 5,
  themeColor: [
    { media: "(prefers-color-scheme: light)", color: "#f8fafc" },
    { media: "(prefers-color-scheme: dark)", color: "#07090e" },
  ],
};

export const metadata: Metadata = {
  metadataBase: new URL("https://ihusnainalii.github.io/SwiftNetworkKit/"),
  title: {
    default: "SwiftNetworkKit - Modern Protocol-Oriented Networking for Swift 6",
    template: "%s | SwiftNetworkKit",
  },
  description:
    "A modern, composable, protocol-oriented networking framework for Swift 6. Zero external dependencies, 13 isolated actors, single-flight 401 token refresh, SPKI SSL pinning, jittered retry, offline queueing, and SwiftUI @Observable state.",
  keywords: [
    "Swift",
    "Swift 6",
    "Networking",
    "Swift Package Manager",
    "SPM",
    "iOS",
    "macOS",
    "visionOS",
    "watchOS",
    "tvOS",
    "URLSession",
    "Strict Concurrency",
    "Actor",
    "TokenManager",
    "OAuth PKCE",
    "SSL Pinning",
    "SPKI Pinning",
    "Alamofire Alternative",
    "Offline Queue",
    "AsyncSequence",
    "Observation",
    "SwiftUI",
    "Sendable",
  ],
  authors: [{ name: "Husnain Ali", url: "https://github.com/ihusnainalii" }],
  creator: "Husnain Ali",
  publisher: "SwiftNetworkKit",
  alternates: {
    canonical: "https://ihusnainalii.github.io/SwiftNetworkKit/",
  },
  openGraph: {
    title: "SwiftNetworkKit - Swift 6 Protocol-Oriented Networking Engine",
    description:
      "Zero external dependencies. 13 isolated Swift actors. SPKI public key pinning. OAuth 2.0 PKCE. Offline request spooling. Built natively for Swift 6 strict concurrency.",
    url: "https://ihusnainalii.github.io/SwiftNetworkKit/",
    siteName: "SwiftNetworkKit",
    locale: "en_US",
    type: "website",
  },
  twitter: {
    card: "summary_large_image",
    title: "SwiftNetworkKit - Modern Networking for Swift 6",
    description:
      "Zero external dependencies. 13 isolated Swift actors. SPKI public key pinning. Built natively for Swift 6 strict concurrency.",
    creator: "@ihusnainalii",
  },
  robots: {
    index: true,
    follow: true,
    googleBot: {
      index: true,
      follow: true,
      "max-video-preview": -1,
      "max-image-preview": "large",
      "max-snippet": -1,
    },
  },
  icons: {
    icon: [
      { url: "/icon.svg", type: "image/svg+xml" },
      { url: "/favicon.svg", type: "image/svg+xml" },
    ],
    apple: [
      { url: "/apple-icon.svg", type: "image/svg+xml" },
    ],
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
        <link rel="icon" type="image/svg+xml" href="icon.svg" />
        <link rel="apple-touch-icon" href="apple-icon.svg" />
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700;800&family=JetBrains+Mono:wght@400;500;600;700&display=swap"
          rel="stylesheet"
        />
      </head>
      <body
        className="font-sans relative bg-slate-50 dark:bg-[#07090e] text-slate-900 dark:text-slate-100"
        suppressHydrationWarning
      >
        <ThemeProvider>{children}</ThemeProvider>
      </body>
    </html>
  );
}
