import Foundation

/// The resolved, immutable pinning rules a ``ServerTrustEvaluator`` works from. Built once from the
/// public ``SSLPinning`` value at `NetworkClient` init — the delegate never does async lookups.
public struct SSLPinningConfiguration: Sendable, Hashable {

    /// Host (lower-cased, no port) -> the pins that host's chain must satisfy. A non-empty pin list.
    public var pins: [String: [Pin]]

    /// Also apply a host's pins to its subdomains (`api.example.com` pins cover `x.api.example.com`).
    public var includeSubdomains: Bool

    /// Run the system chain evaluation (`SecTrustEvaluateWithError`) before checking pins.
    public var validateCertificateChain: Bool

    public var mode: PinningMode

    public init(
        pins: [String: [Pin]],
        includeSubdomains: Bool = false,
        validateCertificateChain: Bool = true,
        mode: PinningMode = .enforced
    ) {
        // An empty pin list would silently "allow all" under .enforced — that is always a bug.
        // .recordOnly legitimately starts with no pins (you are discovering them).
        let emptyHost = pins.first { $0.value.isEmpty }?.key ?? "?"
        precondition(
            mode == .recordOnly || pins.allSatisfy { !$0.value.isEmpty },
            "SSLPinningConfiguration: host \(emptyHost) has no pins — that is a programmer error, not 'allow all'"
        )
        self.pins = Dictionary(uniqueKeysWithValues: pins.map { ($0.key.lowercased(), $0.value) })
        self.includeSubdomains = includeSubdomains
        self.validateCertificateChain = validateCertificateChain
        self.mode = mode
    }

    /// The pin list that applies to `host`, matching exactly or (when enabled) as a parent domain.
    func pins(matching host: String) -> [Pin]? {
        let host = host.lowercased()
        if let exact = pins[host] { return exact }
        guard includeSubdomains else { return nil }
        return pins.first { pinnedHost, _ in
            host == pinnedHost || host.hasSuffix("." + pinnedHost)
        }?.value
    }
}
