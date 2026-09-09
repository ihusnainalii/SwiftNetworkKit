/// SwiftNetworkKit: a composable, protocol-oriented networking layer.
///
/// The public entry point is `NetworkClient`. Configuration lives in
/// ``NetworkConfiguration`` and ``NetworkEnvironment``. Each app defines its own APIs by
/// conforming types to ``Endpoint``; the package itself ships no app-specific code.
public enum SwiftNetworkKit {
    /// Semantic version of the package. Kept in step with the git tag by release-please.
    public static let version = "0.1.6"  // x-release-please-version
}
