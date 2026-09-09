import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The identity of a request for deduplication: method + URL + whether it carries an `Authorization`
/// header (so an authenticated and an anonymous request for the same URL never share a result).
enum DeduplicationKey {
    static func make(_ request: URLRequest) -> String {
        let method = request.httpMethod ?? "GET"
        let url = request.url?.absoluteString ?? "?"
        let auth = request.value(forHTTPHeaderField: "Authorization") != nil ? " +auth" : ""
        return "\(method) \(url)\(auth)"
    }
}
