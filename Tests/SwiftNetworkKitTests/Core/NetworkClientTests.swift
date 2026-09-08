import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("NetworkClient pipeline")
struct NetworkClientTests {

    private struct User: Codable, Equatable, Sendable {
        let id: Int
        let fullName: String
    }

    private struct ProfileEndpoint: Endpoint {
        typealias Response = User
        let path = "/me"
        var authentication: AuthRequirement = .none
    }

    private struct CreateEndpoint: Endpoint {
        typealias Response = EmptyResponse
        let path = "/things"
        var method: HTTPMethod = .post
    }

    private func client(
        _ transport: MockNetworkTransport,
        errorMapper: (@Sendable (ResponseContext) -> NetworkError?)? = nil
    ) -> NetworkClient {
        NetworkClient(
            configuration: NetworkConfiguration(baseURL: "https://api.example.com", errorMapper: errorMapper),
            transport: transport
        )
    }

    @Test("decodes a JSON body into the endpoint's Response")
    func decodesJSON() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"id":1,"full_name":"Ada"}"#.utf8)))
        let user = try await client(transport).request(ProfileEndpoint())
        #expect(user == User(id: 1, fullName: "Ada"))
        #expect(transport.requestCount == 1)
    }

    @Test("5xx maps to NetworkError.server with context")
    func serverError() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.success(status: 503, headers: [:], body: Data(#"{"message":"down"}"#.utf8)))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport).request(ProfileEndpoint())
        }
        #expect(error?.code == .server)
        #expect(error?.statusCode == 503)
        #expect(error?.serverMessage == "down")
    }

    @Test("malformed JSON maps to NetworkError.decoding with context")
    func decodingError() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data("{not json".utf8)))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport).request(ProfileEndpoint())
        }
        #expect(error?.code == .decoding)
        #expect(error?.responseContext != nil)
    }

    @Test("custom errorMapper takes precedence")
    func customErrorMapper() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.success(status: 500, headers: [:], body: Data()))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport, errorMapper: { _ in .sessionExpired }).request(ProfileEndpoint())
        }
        #expect(error?.code == .sessionExpired)
    }

    @Test("data / string / send helpers")
    func helpers() async throws {
        let transport = MockNetworkTransport()
        transport.enqueue(
            .success(status: 200, headers: [:], body: Data("raw".utf8)),
            .success(status: 200, headers: [:], body: Data("text".utf8)),
            .success(status: 204, headers: [:], body: Data())
        )
        let c = client(transport)
        #expect(try await c.data(for: ProfileEndpoint()) == Data("raw".utf8))
        #expect(try await c.string(for: ProfileEndpoint()) == "text")
        try await c.send(CreateEndpoint())
    }

    @Test("completion-handler bridge: success")
    func completionSuccess() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.json(Data(#"{"id":9,"full_name":"Bo"}"#.utf8)))
        let user = await withCheckedContinuation { continuation in
            client(transport).request(ProfileEndpoint()) { result in
                continuation.resume(returning: try? result.get())
            }
        }
        #expect(user == User(id: 9, fullName: "Bo"))
    }

    @Test("completion-handler bridge: failure carries a NetworkError")
    func completionFailure() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.failure(.noInternet))
        let code: NetworkError.Code? = await withCheckedContinuation { continuation in
            client(transport).request(ProfileEndpoint()) { result in
                if case .failure(let error) = result { continuation.resume(returning: error.code) }
                else { continuation.resume(returning: nil) }
            }
        }
        #expect(code == .noInternet)
    }

    @Test("cancelling the handle before latency elapses yields .cancelled")
    func cancellation() async {
        let transport = MockNetworkTransport(latency: .milliseconds(200))
        transport.enqueue(.json(Data(#"{"id":1,"full_name":"x"}"#.utf8)))
        let code: NetworkError.Code? = await withCheckedContinuation { continuation in
            let handle = client(transport).request(ProfileEndpoint()) { result in
                if case .failure(let error) = result { continuation.resume(returning: error.code) }
                else { continuation.resume(returning: nil) }
            }
            handle.cancel()
        }
        #expect(code == .cancelled)
    }

    @Test("transport errors pass through untouched (already NetworkError)")
    func transportErrorPassthrough() async {
        let transport = MockNetworkTransport()
        transport.enqueue(.failure(.sslPinningFailed(host: "api.example.com")))
        let error = await #expect(throws: NetworkError.self) {
            try await client(transport).request(ProfileEndpoint())
        }
        #expect(error?.code == .sslPinningFailed)
    }
}
