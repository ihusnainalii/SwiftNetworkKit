import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("QueryParameters")
struct QueryParametersTests {

    @Test("nil values are omitted; lists expand to repeated keys")
    func basics() {
        let query: QueryParameters = [
            "a": .string("1"),
            "skip": nil,
            "tags": .list(["x", "y"]),
        ]
        let items = query.queryItems()
        #expect(items.count == 3)
        #expect(items.filter { $0.name == "tags" }.count == 2)
        #expect(!items.contains { $0.name == "skip" })
    }

    @Test("plus sign and space are percent-encoded")
    func plusEncoding() {
        let query: QueryParameters = ["q": .string("a+b c")]
        #expect(query.percentEncodedQueryString() == "q=a%2Bb%20c")
    }

    @Test("scalars render predictably")
    func scalars() {
        let query: QueryParameters = ["n": .int(5), "ratio": .double(0.5), "flag": .bool(true)]
        let string = query.percentEncodedQueryString() ?? ""
        #expect(string.contains("n=5"))
        #expect(string.contains("ratio=0.5"))
        #expect(string.contains("flag=true"))
    }

    @Test("insertion order is preserved and duplicates are allowed")
    func ordering() {
        var query = QueryParameters()
        query.append("page", .int(1))
        query.append("page", .int(2))
        let items = query.queryItems()
        #expect(items.map(\.value) == ["1", "2"])
    }

    @Test("empty parameters produce nil query string")
    func empty() {
        #expect(QueryParameters().percentEncodedQueryString() == nil)
    }
}
