import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The identity of a request for deduplication: method + URL + a fingerprint of its `Authorization`
/// value, so requests made with different credentials (or none) never share a result. The key must be
/// built from the request *after* authorization has been applied.
enum DeduplicationKey {
    static func make(_ request: URLRequest) -> String {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "?"
        let auth = AuthFingerprint.suffix(for: request.value(forHTTPHeaderField: "Authorization"))
        return "\(method) \(url)\(auth)"
    }
}
