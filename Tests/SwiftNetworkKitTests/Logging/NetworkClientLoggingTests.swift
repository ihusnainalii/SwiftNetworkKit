import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("NetworkClient logging")
struct NetworkClientLoggingTests {

    private struct Thing: Codable, Sendable { let ok: Bool }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
    }
    private let body = Data(#"{"ok":true}"#.utf8)

    private func client(
        _ transport: MockNetworkTransport,
        level: LogLevel,
        logger: CapturingLogger
    ) -> NetworkClient {
        var env = NetworkEnvironment(kind: .production, baseURL: URL(string: "https://api.example.com")!)
        env.logLevel = level
        var config = NetworkConfiguration(environment: env)
        config.retry = .none
        config.logger = logger
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("LogLevel.none emits nothing")
    func none() async throws {
        let transport = MockNetworkTransport(); transport.enqueue(.json(body))
        let logger = CapturingLogger()
        _ = try await client(transport, level: .none, logger: logger).request(GetThing())
        #expect(logger.lines.isEmpty)
    }

    @Test("LogLevel.basic emits one request line and one response line")
    func basic() async throws {
        let transport = MockNetworkTransport(); transport.enqueue(.json(body))
        let logger = CapturingLogger()
        _ = try await client(transport, level: .basic, logger: logger).request(GetThing())
        #expect(logger.lines.count == 2)
        #expect(logger.lines[0].contains("GET"))
        #expect(logger.lines[0].contains("/thing"))
        #expect(logger.lines[1].contains("200"))
    }

    @Test("LogLevel.verbose adds headers with the token redacted")
    func verbose() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(body, headers: ["Set-Cookie": "s=abc"]))
        let logger = CapturingLogger()

        var env = NetworkEnvironment(kind: .production, baseURL: URL(string: "https://api.example.com")!)
        env.logLevel = .verbose
        var config = NetworkConfiguration(environment: env, authorization: BearerAuth())
        config.retry = .none
        config.logger = logger
        config.tokenStorage = InMemoryTokenStorage(seed: TokenPair(accessToken: "super-secret"))
        let client = NetworkClient(configuration: config, transport: transport)

        struct Secured: Endpoint {
            typealias Response = Thing
            let path = "/thing"
            var authentication: AuthRequirement { .required }
        }
        _ = try await client.request(Secured())

        let all = logger.lines.joined(separator: "\n")
        #expect(all.contains("Authorization: ***"))
        #expect(!all.contains("super-secret"))
        #expect(all.contains("Set-Cookie: ***"))
    }

    @Test("a failure emits one error line at .error level")
    func failure() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.status(500))
        let logger = CapturingLogger()
        _ = try? await client(transport, level: .basic, logger: logger).request(GetThing())
        let errorLines = logger.entries.filter { $0.level == .error }
        #expect(errorLines.count == 1)
        #expect(errorLines[0].line.contains("server"))
    }
}
