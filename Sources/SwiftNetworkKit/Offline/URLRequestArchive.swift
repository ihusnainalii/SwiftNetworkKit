import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// `URLRequest` <-> `Data` via `NSKeyedArchiver` (`NSURLRequest` is `NSSecureCoding`). Method, URL,
/// headers and an in-memory body all survive; a body backed by a temp file does not.
enum URLRequestArchive {
    static func archive(_ request: URLRequest) -> Data? {
        try? NSKeyedArchiver.archivedData(withRootObject: request as NSURLRequest, requiringSecureCoding: true)
    }

    static func unarchive(_ data: Data) -> URLRequest? {
        guard let nsRequest = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSURLRequest.self, from: data) else {
            return nil
        }
        return nsRequest as URLRequest
    }
}
