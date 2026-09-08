import Testing
@testable import SwiftNetworkKit

@Suite("HTTPMethod")
struct HTTPMethodTests {

    @Test("raw values are upper-cased")
    func rawValues() {
        #expect(HTTPMethod.get.rawValue == "GET")
        #expect(HTTPMethod.delete.rawValue == "DELETE")
        #expect(HTTPMethod.custom("report").rawValue == "REPORT")
    }

    @Test("idempotency classification", arguments: [
        (HTTPMethod.get, true),
        (.head, true),
        (.put, true),
        (.delete, true),
        (.options, true),
        (.trace, true),
        (.post, false),
        (.patch, false),
        (.custom("LOCK"), false),
    ])
    func idempotency(method: HTTPMethod, expected: Bool) {
        #expect(method.isIdempotent == expected)
    }

    @Test("parses from raw string, unknown verbs become .custom")
    func parsing() {
        #expect(HTTPMethod(rawValue: "post") == .post)
        #expect(HTTPMethod(rawValue: "GET") == .get)
        #expect(HTTPMethod(rawValue: "purge") == .custom("PURGE"))
    }
}
