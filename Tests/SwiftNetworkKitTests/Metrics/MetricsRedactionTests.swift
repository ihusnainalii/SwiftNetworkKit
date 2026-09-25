import Foundation
import Testing

@_spi(SwiftNetworkKitTesting) @testable import SwiftNetworkKit

/// A metrics sink is often forwarded to a third party, so failure events must not carry credentials.
@Suite("Metrics redaction")
struct MetricsRedactionTests {

    private actor Recorder: NetworkMetrics {
        private(set) var failures: [NetworkError] = []
        func record(_ event: MetricEvent) {
            if case .failure(_, let error, _) = event { failures.append(error) }
        }
    }

    private struct Thing: Codable, Sendable { let v: String }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
        var authentication: AuthRequirement = .required
        var queryParameters: QueryParameters? { ["access_token": .string("QUERYSECRET"), "page": .int(2)] }
    }

    @Test("a failure event has no body, masked credentials and the status code kept")
    func failureEventIsSanitized() async throws {
        let recorder = Recorder()
        let transport = MockNetworkTransport()
        transport.enqueue(
            .success(
                status: 500, headers: ["Set-Cookie": "session=COOKIESECRET"],
                body: Data(#"{"message":"boom","token":"BODYSECRET"}"#.utf8)))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.metrics = recorder
        config.tokenStorage = InMemoryTokenStorage(seed: TokenPair(accessToken: "TOKEN123"))
        let client = NetworkClient(configuration: config, transport: transport)

        await #expect(throws: NetworkError.self) { try await client.request(GetThing()) }

        let error = try #require(await recorder.failures.first)
        let context = try #require(error.responseContext)
        #expect(error.code == .server)
        #expect(context.statusCode == 500)
        #expect(context.data == nil)
        #expect(context.request.value(forHTTPHeaderField: "Authorization") == "***")
        #expect(context.headers["Set-Cookie"] == "***")

        let url = try #require(context.request.url?.absoluteString)
        #expect(url.contains("page=2"))
        #expect(!url.contains("QUERYSECRET"))

    }

    @Test("the error the caller receives is not sanitized")
    func callerErrorKeepsBody() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.success(status: 500, headers: [:], body: Data(#"{"message":"boom"}"#.utf8)))
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tokenStorage = InMemoryTokenStorage(seed: TokenPair(accessToken: "t"))
        let client = NetworkClient(configuration: config, transport: transport)

        let error = await #expect(throws: NetworkError.self) { try await client.request(GetThing()) }
        #expect(error?.serverMessage == "boom")
    }
}
