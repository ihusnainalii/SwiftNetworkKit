/// SwiftNetworkKit — a composable, protocol-oriented networking layer.
///
/// The public entry point (from milestone M1) is `NetworkClient`. Configuration lives in
/// ``NetworkConfiguration`` and ``NetworkEnvironment``. Each app defines its own APIs by
/// conforming types to ``Endpoint`` — the package itself ships no app-specific code.
public enum SwiftNetworkKit {
    /// Semantic version of the package. Milestone-suffixed until v1.
    public static let version = "0.1.0-M0"
}
