import Foundation
import Testing
@testable import SwiftNetworkKit

@Suite("Endpoint default decode")
struct EndpointTests {

    private struct User: Codable, Equatable, Sendable {
        let id: Int
        let fullName: String
    }

    private struct RawEndpoint: Endpoint { typealias Response = Data; let path = "/x" }
    private struct StringEndpoint: Endpoint { typealias Response = String; let path = "/x" }
    private struct EmptyEndpoint: Endpoint { typealias Response = EmptyResponse; let path = "/x" }
    private struct UserEndpoint: Endpoint { typealias Response = User; let path = "/x" }
    
    private struct UnsupportedEndpoint: Endpoint {
        struct NotDecodable: Sendable {}
        typealias Response = NotDecodable
        let path = "/x"
    }

    private func response() -> HTTPURLResponse {
        HTTPURLResponse(url: URL(string: "https://e.com/x")!, statusCode: 200, httpVersion: nil, headerFields: nil)!
    }

    @Test("Data passes through unchanged")
    func dataPassthrough() throws {
        let bytes = Data([1, 2, 3])
        #expect(try RawEndpoint().decode(bytes, response: response(), using: .networkKitDefault) == bytes)
    }

    @Test("String decodes UTF-8")
    func stringDecode() throws {
        let value = try StringEndpoint().decode(Data("hello".utf8), response: response(), using: .networkKitDefault)
        #expect(value == "hello")
    }

    @Test("EmptyResponse ignores the body")
    func emptyResponse() throws {
        _ = try EmptyEndpoint().decode(Data("noise".utf8), response: response(), using: .networkKitDefault)
    }

    @Test("Decodable uses the snake_case decoder")
    func decodable() throws {
        let json = Data(#"{"id":7,"full_name":"Ada"}"#.utf8)
        let user = try UserEndpoint().decode(json, response: response(), using: .networkKitDefault)
        #expect(user == User(id: 7, fullName: "Ada"))
    }

    @Test("malformed JSON throws NetworkError.decoding")
    func malformedJSON() {
        let error = #expect(throws: NetworkError.self) {
            try UserEndpoint().decode(Data("{not json".utf8), response: response(), using: .networkKitDefault)
        }
        #expect(error?.code == .decoding)
    }

    @Test("non-decodable response type throws a clear .decoding error")
    func unsupportedType() {
        let error = #expect(throws: NetworkError.self) {
            try UnsupportedEndpoint().decode(Data(), response: response(), using: .networkKitDefault)
        }
        #expect(error?.code == .decoding)
    }

    @Test("protocol defaults are sane")
    func defaults() {
        let endpoint = RawEndpoint()
        #expect(endpoint.method == .get)
        #expect(endpoint.authentication == .none)
        #expect(endpoint.headers.isEmpty)
        #expect(endpoint.queryParameters == nil)
        #expect(endpoint.body == nil)
        #expect(endpoint.priority == .normal)
        #expect(endpoint.timeout == nil)
        #expect(endpoint.decoder == nil)
    }
}
