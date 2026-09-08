import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("Redactor")
struct RedactorTests {

    @Test("denylisted headers are replaced with ***")
    func headers() {
        let redactor = Redactor(redactedHeaders: ["x-api-key"])
        let input: HTTPHeaders = [
            "Authorization": "Bearer secret-token",
            "Cookie": "session=abc",
            "Set-Cookie": "session=abc",
            "X-API-Key": "k-123",
            "Accept": "application/json",
        ]
        let out = redactor.redact(headers: input)
        #expect(out["Authorization"] == "***")
        #expect(out["Cookie"] == "***")
        #expect(out["Set-Cookie"] == "***")
        #expect(out["X-API-Key"] == "***")
        #expect(out["Accept"] == "application/json")
    }

    @Test("denylisted JSON body keys are replaced, nested and in arrays")
    func body() {
        let redactor = Redactor(redactedBodyKeys: ["password", "refresh_token"])
        let data = Data(#"{"user":"ada","password":"hunter2","tokens":[{"refresh_token":"r1"}]}"#.utf8)
        let out = redactor.redact(body: data)
        #expect(!out.contains("hunter2"))
        #expect(!out.contains("r1"))
        #expect(out.contains("ada"))
        #expect(out.contains("***"))
    }

    @Test("non-JSON body is summarized, never echoed")
    func nonJSON() {
        let redactor = Redactor()
        #expect(redactor.redact(body: Data("plain secret text".utf8)) == "<17 bytes>")
        #expect(redactor.redact(body: Data()) == "<empty>")
    }
}
