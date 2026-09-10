import Foundation

/// Every knob the Settings screen exposes. Persisted as JSON in `UserDefaults`; a change only
/// reaches the live `NetworkClient` when the user taps "Apply".
struct DemoSettings: Codable, Equatable, Sendable {

    // MARK: Connection

    var baseURL: String
    var timeout: Double
    var logLevel: Int  // LogLevel.rawValue

    // MARK: Retry

    enum RetryPreset: String, Codable, CaseIterable, Sendable {
        case none, standard, aggressive
        var label: String {
            switch self {
            case .none: "None (1 attempt)"
            case .standard: "Default (3, backoff + jitter)"
            case .aggressive: "Aggressive (5, wide backoff)"
            }
        }
    }
    var retry: RetryPreset

    // MARK: Request management

    var maxConcurrentRequests: Int
    var deduplication: Bool

    // MARK: Cache

    var cacheEnabled: Bool
    var cachePolicy: String  // CachePolicy raw name
    var cacheTTL: Double

    // MARK: Certificate / public-key pinning

    enum PinningMode: String, Codable, CaseIterable, Sendable {
        case off, recordOnly, publicKeys, certificate
        var label: String {
            switch self {
            case .off: "Off"
            case .recordOnly: "Record only"
            case .publicKeys: "Public-key hashes"
            case .certificate: "Certificate file"
            }
        }
        var explanation: String {
            switch self {
            case .off: "Normal system TLS. No pinning."
            case .recordOnly:
                "Never blocks. Logs the observed sha256/... SPKI hash for each host so you can copy it into an enforcing pin."
            case .publicKeys:
                "Enforces one or more SubjectPublicKeyInfo SHA-256 hashes. Survives certificate renewal with the same key."
            case .certificate:
                "Enforces against imported .cer / .der certificate files. Pin the leaf or an intermediate."
            }
        }
    }
    var pinningMode: PinningMode
    var pinnedHost: String
    var pinnedPublicKeys: [String]
    /// DER bytes of imported certificates, plus a display name.
    var pinnedCertificates: [PinnedCertificate]

    struct PinnedCertificate: Codable, Equatable, Sendable, Identifiable {
        var id: UUID = UUID()
        var name: String
        var der: Data
    }

    // MARK: Privacy

    var redactedBodyKeys: [String]

    // MARK: Presets

    static let baseURLPresets: [String] = [
        "https://jsonplaceholder.typicode.com",
        "https://httpbin.org",
        "https://api.github.com",
    ]

    static let `default` = DemoSettings(
        baseURL: "https://jsonplaceholder.typicode.com",
        timeout: 30,
        logLevel: 2,  // .basic
        retry: .standard,
        maxConcurrentRequests: 4,
        deduplication: true,
        cacheEnabled: true,
        cachePolicy: "cacheFirst",
        cacheTTL: 120,
        pinningMode: .off,
        pinnedHost: "jsonplaceholder.typicode.com",
        pinnedPublicKeys: [],
        pinnedCertificates: [],
        redactedBodyKeys: ["ssn", "card_number"]
    )
}
