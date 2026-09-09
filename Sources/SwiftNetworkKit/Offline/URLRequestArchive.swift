import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// `URLRequest` <-> `Data` as portable JSON. Method, URL, headers and an in-memory body survive; a
/// body backed by a stream (temp file) does not. JSON rather than `NSKeyedArchiver` so the format is
/// identical on every platform (swift-corelibs-foundation's `NSSecureCoding` for `NSURLRequest`
/// traps on nested `NSURL`).
enum URLRequestArchive {

    private struct Wire: Codable {
        var url: String
        var method: String?
        var headers: [String: String]?
        var body: Data?
        var timeout: Double
        var cachePolicy: UInt
    }

    static func archive(_ request: URLRequest) -> Data? {
        guard let url = request.url?.absoluteString else { return nil }
        let wire = Wire(
            url: url,
            method: request.httpMethod,
            headers: request.allHTTPHeaderFields,
            body: request.httpBody,
            timeout: request.timeoutInterval,
            cachePolicy: request.cachePolicy.rawValue)
        return try? JSONEncoder().encode(wire)
    }

    static func unarchive(_ data: Data) -> URLRequest? {
        guard let wire = try? JSONDecoder().decode(Wire.self, from: data),
            let url = URL(string: wire.url)
        else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = wire.method
        for (name, value) in wire.headers ?? [:] {
            request.setValue(value, forHTTPHeaderField: name)
        }
        request.httpBody = wire.body
        request.timeoutInterval = wire.timeout
        if let policy = URLRequest.CachePolicy(rawValue: wire.cachePolicy) {
            request.cachePolicy = policy
        }
        return request
    }
}
