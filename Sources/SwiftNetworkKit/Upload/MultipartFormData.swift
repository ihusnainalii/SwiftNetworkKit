import Foundation

/// Builds an RFC 7578 `multipart/form-data` body.
///
/// ```swift
/// var form = MultipartFormData()
/// form.append("caption text", name: "caption")
/// form.append(imageData, name: "photo", fileName: "cat.jpg", mimeType: "image/jpeg")
/// try await client.upload(UploadPhoto(), from: .multipart(form)) { print($0.fraction ?? 0) }
/// ```
public struct MultipartFormData: Sendable {

    public let boundary: String
    private var parts: [MultipartPart] = []

    public init(boundary: String = "SwiftNetworkKit.boundary.\(UUID().uuidString)") {
        self.boundary = boundary
    }

    /// `multipart/form-data; boundary=…` — set as the request's `Content-Type`.
    public var contentType: String { "multipart/form-data; boundary=\(boundary)" }

    // MARK: Appending

    public mutating func append(_ data: Data, name: String, fileName: String? = nil, mimeType: String? = nil) {
        parts.append(MultipartPart(name: name, fileName: fileName, mimeType: mimeType, source: .data(data)))
    }

    public mutating func append(_ text: String, name: String) {
        append(Data(text.utf8), name: name)
    }

    /// Appends a file part; its bytes are read when the body is encoded, not now.
    public mutating func append(
        _ fileURL: URL,
        name: String,
        fileName: String? = nil,
        mimeType: String? = nil
    ) {
        parts.append(MultipartPart(
            name: name,
            fileName: fileName ?? fileURL.lastPathComponent,
            mimeType: mimeType ?? Self.mimeType(for: fileURL),
            source: .file(fileURL)
        ))
    }

    // MARK: Encoding

    /// The full body in memory. For very large files prefer ``writeEncoded(to:)`` + `.file`.
    public func encoded() throws -> Data {
        var body = Data()
        for part in parts {
            body.append(Data("--\(boundary)\r\n".utf8))
            body.append(part.header)
            body.append(try part.payload())
            body.append(Data("\r\n".utf8))
        }
        body.append(Data("--\(boundary)--\r\n".utf8))
        return body
    }

    /// Streams the body to `url` part-by-part so a large file part is never fully in memory.
    public func writeEncoded(to url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: nil)
        guard let handle = try? FileHandle(forWritingTo: url) else {
            throw NetworkError.encoding(underlying: MultipartError.cannotOpenOutput(url))
        }
        defer { try? handle.close() }
        do {
            for part in parts {
                try handle.write(contentsOf: Data("--\(boundary)\r\n".utf8))
                try handle.write(contentsOf: part.header)
                switch part.source {
                case .data(let data):
                    try handle.write(contentsOf: data)
                case .file(let fileURL):
                    let reader = try FileHandle(forReadingFrom: fileURL)
                    defer { try? reader.close() }
                    while case let chunk = try reader.read(upToCount: 1 << 16) ?? Data(), !chunk.isEmpty {
                        try handle.write(contentsOf: chunk)
                    }
                }
                try handle.write(contentsOf: Data("\r\n".utf8))
            }
            try handle.write(contentsOf: Data("--\(boundary)--\r\n".utf8))
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.encoding(underlying: asSendableError(error))
        }
    }

    private static func mimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "jpg", "jpeg": "image/jpeg"
        case "png": "image/png"
        case "gif": "image/gif"
        case "pdf": "application/pdf"
        case "json": "application/json"
        case "txt": "text/plain"
        case "mp4": "video/mp4"
        default: "application/octet-stream"
        }
    }
}

/// Multipart encoding failures that aren't a wrapped Foundation error.
enum MultipartError: Error, Sendable {
    case cannotOpenOutput(URL)
}
