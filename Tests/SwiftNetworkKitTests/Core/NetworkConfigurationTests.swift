import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("NetworkConfiguration & NetworkEnvironment")
struct NetworkConfigurationTests {

    @Test("string baseURL convenience initializer")
    func stringBaseURL() {
        let config = NetworkConfiguration(baseURL: "https://api.example.com")
        #expect(config.environment.baseURL.absoluteString == "https://api.example.com")
        #expect(config.environment.kind == .production)
        #expect(config.environment.timeout == 60)
    }

    @Test("redaction sets are populated and lower-cased")
    func redaction() {
        let config = NetworkConfiguration(baseURL: "https://x.com", headers: ["A": "b"])
        #expect(config.redactedHeaders.contains("authorization"))
        #expect(config.redactedHeaders.contains("set-cookie"))
        #expect(config.redactedBodyKeys.contains("refresh_token"))

        let custom = NetworkConfiguration(
            environment: .production(baseURL: URL(string: "https://x.com")!),
            redactedHeaders: ["X-Secret"]
        )
        #expect(custom.redactedHeaders.contains("x-secret"))
    }

    @Test("error mapper is retained")
    func errorMapper() {
        let config = NetworkConfiguration(baseURL: "https://x.com") { _ in .sessionExpired }
        let context = ResponseContext(
            statusCode: 500, headers: [:], data: nil,
            request: URLRequest(url: URL(string: "https://x.com")!)
        )
        #expect(config.errorMapper?(context)?.code == .sessionExpired)
    }

    @Test("environment factories carry sensible log levels")
    func environmentFactories() {
        let url = URL(string: "https://x.com")!
        #expect(NetworkEnvironment.development(baseURL: url).logLevel == .debug)
        #expect(NetworkEnvironment.qa(baseURL: url).logLevel == .verbose)
        #expect(NetworkEnvironment.staging(baseURL: url).logLevel == .basic)
        #expect(NetworkEnvironment.production(baseURL: url).logLevel == .error)
    }

    @Test("environment kinds are exhaustive")
    func environmentKinds() {
        #expect(Set(EnvironmentKind.allCases) == [.development, .qa, .staging, .production])
    }
}
