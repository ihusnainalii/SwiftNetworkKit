import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("RequestBody")
struct RequestBodyTests {

    private struct Payload: Codable, Sendable {
        let userName: String
    }

    @Test("json encodes with snake_case keys and application/json content type")
    func json() throws {
        let (data, contentType) = try RequestBody.json(Payload(userName: "sam")).encoded()
        #expect(contentType == "application/json")
        let string = try #require(String(data: data, encoding: .utf8))
        #expect(string.contains("user_name"))
    }

    @Test("formURLEncoded is sorted, percent-encoded, and typed")
    func formURLEncoded() throws {
        let (data, contentType) = try RequestBody.formURLEncoded(["b": "2", "a": "x y"]).encoded()
        #expect(contentType?.hasPrefix("application/x-www-form-urlencoded") == true)
        #expect(String(data: data, encoding: .utf8) == "a=x%20y&b=2")
    }

    @Test("raw data passes through with no content type")
    func rawData() throws {
        let (data, contentType) = try RequestBody.data(Data([9, 9, 9])).encoded()
        #expect(data == Data([9, 9, 9]))
        #expect(contentType == nil)
    }

    @Test("encoding failure surfaces as NetworkError.encoding")
    func encodingFailure() {
        struct Bad: Encodable, Sendable {
            func encode(to encoder: any Encoder) throws {
                throw EndpointDecodingFailure.responseNotUTF8
            }
        }
        let error = #expect(throws: NetworkError.self) {
            try RequestBody.json(Bad()).encoded()
        }
        #expect(error?.code == .encoding)
    }
}
