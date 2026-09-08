import Foundation
import Testing

@testable import SwiftNetworkKit

@Suite("MultipartFormData")
struct MultipartFormDataTests {

    @Test("encodes two fields and a file part byte-for-byte per RFC 7578")
    func byteExact() throws {
        var form = MultipartFormData(boundary: "TESTBOUNDARY")
        form.append("hello", name: "caption")
        form.append(Data("DATA".utf8), name: "file", fileName: "a.txt", mimeType: "text/plain")

        let expected = [
            "--TESTBOUNDARY\r\n",
            "Content-Disposition: form-data; name=\"caption\"\r\n",
            "\r\n",
            "hello\r\n",
            "--TESTBOUNDARY\r\n",
            "Content-Disposition: form-data; name=\"file\"; filename=\"a.txt\"\r\n",
            "Content-Type: text/plain\r\n",
            "\r\n",
            "DATA\r\n",
            "--TESTBOUNDARY--\r\n",
        ].joined()

        #expect(try form.encoded() == Data(expected.utf8))
        #expect(form.contentType == "multipart/form-data; boundary=TESTBOUNDARY")
    }

    @Test("a file-URL part reads its bytes and infers filename + mime type")
    func fileURLPart() throws {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent("mp-\(UUID()).png")
        try Data("PNGBYTES".utf8).write(to: url)
        defer { try? FileManager.default.removeItem(at: url) }

        var form = MultipartFormData(boundary: "B")
        form.append(url, name: "avatar")

        let body = String(data: try form.encoded(), encoding: .utf8)!
        #expect(body.contains("filename=\"\(url.lastPathComponent)\""))
        #expect(body.contains("Content-Type: image/png"))
        #expect(body.contains("PNGBYTES"))
    }

    @Test("CRLF and quotes in name / filename cannot forge part headers")
    func headerInjectionIsEscaped() throws {
        var form = MultipartFormData(boundary: "B")
        form.append(
            Data("X".utf8),
            name: "field",
            fileName: "a.jpg\r\nContent-Type: text/plain\r\n\r\ninjected\r\n--B\r\nname=\"role\"\r\n\r\nadmin",
            mimeType: "image/jpeg\r\nX-Evil: 1"
        )
        let body = String(data: try form.encoded(), encoding: .utf8)!

        // Exactly one Content-Disposition line and one boundary opener for the single part.
        #expect(body.components(separatedBy: "Content-Disposition:").count == 2)
        #expect(body.components(separatedBy: "--B\r\n").count == 2)
        #expect(!body.contains("\r\n\r\ninjected"))
        #expect(!body.contains("X-Evil"))
        #expect(body.contains("%0D%0A"))  // the CRLF was percent-encoded, not passed through
    }

    @Test("writeEncoded streams the same bytes as encoded()")
    func writeEncodedMatchesInMemory() throws {
        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("part-\(UUID()).bin")
        try Data(repeating: 0x41, count: 200_000).write(to: fileURL)
        defer { try? FileManager.default.removeItem(at: fileURL) }

        var form = MultipartFormData(boundary: "B")
        form.append("meta", name: "kind")
        form.append(fileURL, name: "blob", fileName: "blob.bin", mimeType: "application/octet-stream")

        let out = FileManager.default.temporaryDirectory.appendingPathComponent("out-\(UUID()).bin")
        defer { try? FileManager.default.removeItem(at: out) }
        try form.writeEncoded(to: out)

        #expect(try Data(contentsOf: out) == (try form.encoded()))
    }
}
