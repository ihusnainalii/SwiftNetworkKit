import Foundation
import Testing

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

@testable import SwiftNetworkKit

@Suite("HTTPHeaders")
struct HTTPHeadersTests {

    @Test("get and set are case-insensitive; last spelling wins")
    func caseInsensitive() {
        var headers: HTTPHeaders = ["Content-Type": "application/json"]
        #expect(headers["content-type"] == "application/json")
        #expect(headers["CONTENT-TYPE"] == "application/json")

        headers["content-type"] = "text/plain"
        #expect(headers.count == 1)
        #expect(headers["Content-Type"] == "text/plain")
    }

    @Test("add appends comma-joined")
    func add() {
        var headers = HTTPHeaders()
        headers.add(name: "Accept", value: "text/html")
        headers.add(name: "accept", value: "application/json")
        #expect(headers["Accept"] == "text/html, application/json")
        #expect(headers.count == 1)
    }

    @Test("setting nil removes the field")
    func removal() {
        var headers: HTTPHeaders = ["X-Debug": "1"]
        headers["x-debug"] = nil
        #expect(headers.isEmpty)
    }

    @Test("merging strategies")
    func merging() {
        let base: HTTPHeaders = ["X-A": "1", "X-B": "2"]
        let overlay: HTTPHeaders = ["x-b": "20", "X-C": "3"]

        let overridden = base.merging(overlay, strategy: .override)
        #expect(overridden["X-B"] == "20")
        #expect(overridden["X-C"] == "3")
        #expect(overridden.count == 3)

        let kept = base.merging(overlay, strategy: .keepCurrent)
        #expect(kept["X-B"] == "2")
        #expect(kept["X-C"] == "3")
    }

    @Test("builds from an HTTPURLResponse header dictionary")
    func fromResponseDictionary() {
        let raw: [AnyHashable: Any] = ["Content-Length": 42, "ETag": "\"abc\""]
        let headers = HTTPHeaders(raw)
        #expect(headers["content-length"] == "42")
        #expect(headers["etag"] == "\"abc\"")
    }

    @Test("dictionary snapshot uses preserved names")
    func dictionarySnapshot() {
        let headers: HTTPHeaders = ["X-Trace-ID": "abc"]
        #expect(headers.dictionary == ["X-Trace-ID": "abc"])
    }
}
