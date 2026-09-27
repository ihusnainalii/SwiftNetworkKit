import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

/// `NetworkClient.validated(configuration:...)` throws instead of trapping when the default transport
/// can't be built. The plain initializer's own trapping behavior is unchanged and untested here.
@Suite("NetworkClient.validated")
struct NetworkClientValidatedInitTests {

    @Test("a valid configuration succeeds, same as the plain initializer")
    func succeedsWithAValidConfiguration() throws {
        let client = try NetworkClient.validated(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com"))
        #expect(client.configuration.environment.baseURL.absoluteString == "https://api.example.com")
    }

    @Test("an injected transport skips pinning resolution entirely")
    func injectedTransportSkipsResolution() throws {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        // A pin hash this malformed would fail resolution if it were ever resolved.
        config.sslPinning = .publicKeys(["not-valid-base64!!"], hosts: ["api.example.com"])
        // Supplying a transport bypasses defaultTransport()/throwingDefaultTransport() altogether.
        _ = try NetworkClient.validated(configuration: config, transport: MockNetworkTransport())
    }

    #if canImport(Security)
    @Test("an unresolvable pinning configuration throws instead of trapping")
    func throwsOnInvalidPinning() throws {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.sslPinning = .publicKeys(["not-valid-base64!!"], hosts: ["api.example.com"])

        let error = try #require(throws: NetworkClientInitializationError.self) {
            _ = try NetworkClient.validated(configuration: config)
        }
        guard case .invalidPinningConfiguration(let underlying) = error else {
            Issue.record("expected .invalidPinningConfiguration, got \(error)")
            return
        }
        #expect(underlying == .invalidPublicKeyHash("not-valid-base64!!"))
    }
    #endif
}
