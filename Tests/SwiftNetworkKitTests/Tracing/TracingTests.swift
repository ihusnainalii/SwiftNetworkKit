import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("Tracing")
struct TracingTests {

    private struct Ping: Endpoint {
        typealias Response = Data
        let path = "/ping"
    }

    private func client(_ transport: MockNetworkTransport, tracing: TraceHeaders = TraceHeaders()) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.tracing = tracing
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("every request gets a unique X-Request-ID")
    func uniqueRequestID() async throws {
        let transport = MockNetworkTransport(default: .success(status: 200, headers: [:], body: Data()))
        let c = client(transport)
        _ = try await c.data(for: Ping())
        _ = try await c.data(for: Ping())

        let ids = transport.recordedRequests.compactMap { $0.value(forHTTPHeaderField: "X-Request-ID") }
        #expect(ids.count == 2)
        #expect(ids[0] != ids[1])
        #expect(UUID(uuidString: ids[0]) != nil)
    }

    @Test("correlation id is constant within a withCorrelation block and absent outside")
    func correlationID() async throws {
        let transport = MockNetworkTransport(default: .success(status: 200, headers: [:], body: Data()))
        let c = client(transport)

        try await c.withCorrelation("checkout-42") {
            _ = try await c.data(for: Ping())
            _ = try await c.data(for: Ping())
        }
        _ = try await c.data(for: Ping())

        let correlations = transport.recordedRequests.map { $0.value(forHTTPHeaderField: "X-Correlation-ID") }
        #expect(correlations == ["checkout-42", "checkout-42", nil])
    }

    @Test("TraceHeaders.disabled attaches nothing")
    func disabled() async throws {
        let transport = MockNetworkTransport(default: .success(status: 200, headers: [:], body: Data()))
        _ = try await client(transport, tracing: .disabled).data(for: Ping())
        let request = try #require(transport.recordedRequests.first)
        #expect(request.value(forHTTPHeaderField: "X-Request-ID") == nil)
        #expect(request.value(forHTTPHeaderField: "X-Correlation-ID") == nil)
    }

    @Test("W3C traceparent format")
    func traceparent() {
        let value = TracingInterceptor.traceparent()
        let parts = value.split(separator: "-")
        #expect(parts.count == 4)
        #expect(parts[0] == "00")
        #expect(parts[1].count == 32)
        #expect(parts[2].count == 16)
        #expect(parts[3] == "01")
    }
}
