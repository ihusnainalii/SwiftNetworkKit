import Foundation

/// What to send as an upload's request body. `.file` streams from disk (best for large payloads).
public enum UploadBody: Sendable {
    case data(Data)
    case file(URL)
    case multipart(MultipartFormData)
}
