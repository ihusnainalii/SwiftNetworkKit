import Foundation

/// One `multipart/form-data` part: its `Content-Disposition` fields and where its bytes come from.
struct MultipartPart: Sendable {
    let name: String
    let fileName: String?
    let mimeType: String?
    let source: Source

    enum Source: Sendable {
        case data(Data)
        case file(URL)
    }

    /// The RFC 7578 header block for this part (everything before the payload bytes).
    var header: Data {
        var disposition = #"Content-Disposition: form-data; name="\#(Self.escaped(name))""#
        if let fileName { disposition += #"; filename="\#(Self.escaped(fileName))""# }
        var lines = [disposition]
        if let mimeType { lines.append("Content-Type: \(Self.sanitizedToken(mimeType))") }
        return Data((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
    }

    /// RFC 7578 §5.1: CR, LF and `"` in a `name` or `filename` are percent-encoded so a
    /// caller-supplied filename cannot forge part headers or inject a whole extra part.
    private static func escaped(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\r\n", with: "%0D%0A")
            .replacingOccurrences(of: "\r", with: "%0D")
            .replacingOccurrences(of: "\n", with: "%0A")
            .replacingOccurrences(of: "\"", with: "%22")
    }

    /// A MIME type never legitimately contains a control character; truncate at the first one so a
    /// value like `image/jpeg\r\nX-Evil: 1` cannot smuggle a header.
    private static func sanitizedToken(_ value: String) -> String {
        let end = value.unicodeScalars.firstIndex { CharacterSet.controlCharacters.contains($0) }
        return String(String.UnicodeScalarView(value.unicodeScalars[..<(end ?? value.unicodeScalars.endIndex)]))
    }

    /// Reads this part's payload into memory.
    func payload() throws -> Data {
        switch source {
        case .data(let data):
            return data
        case .file(let url):
            do {
                return try Data(contentsOf: url)
            } catch {
                throw NetworkError.encoding(underlying: asSendableError(error))
            }
        }
    }
}
