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
        var disposition = #"Content-Disposition: form-data; name="\#(name)""#
        if let fileName { disposition += #"; filename="\#(fileName)""# }
        var lines = [disposition]
        if let mimeType { lines.append("Content-Type: \(mimeType)") }
        return Data((lines.joined(separator: "\r\n") + "\r\n\r\n").utf8)
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
