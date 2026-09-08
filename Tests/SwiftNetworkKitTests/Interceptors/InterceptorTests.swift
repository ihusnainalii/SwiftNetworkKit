import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("Interceptors")
struct InterceptorTests {

    private struct Thing: Codable, Equatable, Sendable { let ok: Bool }
    private struct GetThing: Endpoint {
        typealias Response = Thing
        let path = "/thing"
    }
    private let body = Data(#"{"ok":true}"#.utf8)

    private struct AddHeader: RequestInterceptor {
        let name: String
        let value: String
        func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
            var request = request
            request.setValue(value, forHTTPHeaderField: name)
            return request
        }
    }

    private struct MapEnvelopeToForbidden: ResponseInterceptor {
        func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
            if let data = context.data, String(data: data, encoding: .utf8)?.contains("NEEDS_2FA") == true {
                return .fail(.forbidden(context))
            }
            return .proceed
        }
    }

    private func client(
        _ transport: MockNetworkTransport,
        request: [any RequestInterceptor] = [],
        response: [any ResponseInterceptor] = []
    ) -> NetworkClient {
        var config = NetworkConfiguration(baseURL: "https://api.example.com")
        config.retry = .none
        config.requestInterceptors = request
        config.responseInterceptors = response
        return NetworkClient(configuration: config, transport: transport)
    }

    @Test("a request interceptor's header reaches the transport")
    func requestInterceptorAddsHeader() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(body))
        _ = try await client(transport, request: [AddHeader(name: "X-App-Version", value: "9.9.9")])
            .request(GetThing())
        #expect(transport.recordedRequests.first?.value(forHTTPHeaderField: "X-App-Version") == "9.9.9")
    }

    @Test("a response interceptor can fail the request from the body")
    func responseInterceptorFails() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"code":"NEEDS_2FA"}"#.utf8)))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport, response: [MapEnvelopeToForbidden()]).request(GetThing())
        }
        #expect(error?.code == .forbidden)
    }

    @Test("a response interceptor can substitute the body")
    func responseInterceptorSubstitutes() async throws {
        struct Substitute: ResponseInterceptor {
            func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
                .substitute(Data(#"{"ok":true}"#.utf8))
            }
        }
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"garbage":1}"#.utf8)))
        let thing = try await client(transport, response: [Substitute()]).request(GetThing())
        #expect(thing == Thing(ok: true))
    }

    @Test("interceptor-driven retries are capped at 2")
    func interceptorRetryCap() async throws {
        struct AlwaysRetry: ResponseInterceptor {
            func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome {
                .retry(after: 0)
            }
        }
        let transport = MockNetworkTransport(default: .json(Data(#"{"ok":true}"#.utf8)))
        _ = try await client(transport, response: [AlwaysRetry()]).request(GetThing())
        // original attempt + 2 interceptor retries
        #expect(transport.requestCount == 3)
    }
}
