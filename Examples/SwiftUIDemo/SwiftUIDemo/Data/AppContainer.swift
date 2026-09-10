import Foundation
@_spi(SwiftNetworkKitTesting) import SwiftNetworkKit

/// Composition root. Builds the `NetworkClient` from ``DemoSettings`` and wires the concrete
/// repositories. Injected through the SwiftUI environment; rebuilt whenever settings are applied.
struct AppContainer: Sendable {
    let users: any UsersRepository
    let userContent: any UserContentRepository
    let composer: any PostComposer
    let diagnostics: any NetworkDiagnostics
    let media: any MediaDownloader
    let client: NetworkClient
    /// Non-nil when a requested pinning config was invalid and the client fell back to system TLS.
    let pinningWarning: String?

    static let live = AppContainer.make(from: .default)

    static func make(from settings: DemoSettings) -> AppContainer {
        let metrics = InMemoryMetrics()
        let url = URL(string: settings.baseURL) ?? URL(string: "https://jsonplaceholder.typicode.com")!
        let level = LogLevel(rawValue: settings.logLevel) ?? .basic

        var configuration = NetworkConfiguration(
            environment: NetworkEnvironment(
                kind: .production,
                baseURL: url,
                defaultHeaders: ["Accept": "application/json"],
                timeout: settings.timeout,
                logLevel: level
            ),
            redactedBodyKeys: NetworkConfiguration.defaultRedactedBodyKeys
                .union(settings.redactedBodyKeys),
            retry: retryPolicy(settings.retry),
            requestInterceptors: [ClientHeaderInterceptor()],
            metrics: metrics,
            cache: cacheConfiguration(settings),
            maxConcurrentRequests: max(1, settings.maxConcurrentRequests),
            enableDeduplication: settings.deduplication
        )

        var pinningWarning: String?
        let requested = pinning(from: settings, host: settings.pinnedHost)
        if let requested {
            do {
                _ = try requested.resolve(defaultHost: settings.pinnedHost)
                configuration.sslPinning = requested
            } catch {
                pinningWarning = "Pinning config rejected (\(error)); using system TLS."
            }
        }

        let monitor = PathNetworkMonitor()
        let offlineStore = InMemoryOfflineStore()
        configuration.networkMonitor = monitor
        configuration.offlineStore = offlineStore
        let client = NetworkClient(configuration: configuration)

        return AppContainer(
            users: LiveUsersRepository(client: client),
            userContent: LiveUserContentRepository(client: client),
            composer: LivePostComposer(client: client),
            diagnostics: LiveNetworkDiagnostics(
                client: client, metrics: metrics, monitor: monitor, offlineStore: offlineStore),
            media: LiveMediaDownloader(client: client),
            client: client,
            pinningWarning: pinningWarning
        )
    }

    // MARK: Settings -> SwiftNetworkKit types

    private static func retryPolicy(_ preset: DemoSettings.RetryPreset) -> RetryPolicy {
        switch preset {
        case .none: .none
        case .standard: .default
        case .aggressive: .aggressive
        }
    }

    static let cachePolicyNames: [(name: String, policy: CachePolicy)] = [
        ("ignoreCache", .ignoreCache),
        ("networkOnly", .networkOnly),
        ("cacheFirst", .cacheFirst),
        ("networkFirst", .networkFirst),
        ("cacheOnly", .cacheOnly),
        ("staleWhileRevalidate", .staleWhileRevalidate),
    ]

    private static func cacheConfiguration(_ settings: DemoSettings) -> CacheConfiguration {
        guard settings.cacheEnabled else { return .disabled }
        let policy = cachePolicyNames.first { $0.name == settings.cachePolicy }?.policy ?? .cacheFirst
        return CacheConfiguration(
            store: MemoryCacheStore(limitBytes: 8 * 1024 * 1024),
            defaultPolicy: policy,
            defaultTTL: settings.cacheTTL
        )
    }

    private static func pinning(from settings: DemoSettings, host: String) -> SSLPinning? {
        let hosts = host.isEmpty ? [] : [host]
        switch settings.pinningMode {
        case .off:
            return nil
        case .recordOnly:
            return .development(.publicKeys([], hosts: hosts))
        case .publicKeys:
            let keys = settings.pinnedPublicKeys.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
            return keys.isEmpty ? nil : .publicKeys(keys, hosts: hosts)
        case .certificate:
            let ders = settings.pinnedCertificates.map(\.der)
            return ders.isEmpty ? nil : .certificates(ders, hosts: hosts)
        }
    }
}
