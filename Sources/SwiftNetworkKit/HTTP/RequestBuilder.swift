import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Builds a `URLRequest` from an ``Endpoint`` and the active ``NetworkEnvironment``.
///
/// Responsibilities: resolve the base URL, substitute `:path` tokens, append the path with exactly
/// one separating slash, attach the percent-encoded query, merge headers (environment first, then
/// endpoint — endpoint wins), encode the body and set its `Content-Type`, and apply the timeout.
enum RequestBuilder {

    static func build(
        endpoint: some Endpoint,
        environment: NetworkEnvironment,
        configuration: NetworkConfiguration
    ) throws -> URLRequest {
        let base = endpoint.baseURL ?? environment.baseURL

        var path = endpoint.path
        for (key, value) in endpoint.pathParameters {
            path = path.replacingOccurrences(of: ":\(key)", with: Self.encodePathParameter(value))
        }

        let trimmedBase =
            base.absoluteString.hasSuffix("/")
            ? String(base.absoluteString.dropLast())
            : base.absoluteString
        let normalizedPath = path.isEmpty || path.hasPrefix("/") ? path : "/" + path
        let combined = trimmedBase + normalizedPath

        guard var url = URL(string: combined) else {
            throw NetworkError.invalidURL(combined)
        }

        if let query = endpoint.queryParameters, let queryString = query.percentEncodedQueryString() {
            guard var components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw NetworkError.invalidURL(combined + "?" + queryString)
            }
            components.percentEncodedQuery = queryString
            guard let withQuery = components.url else {
                throw NetworkError.invalidURL(combined + "?" + queryString)
            }
            url = withQuery
        }

        var request = URLRequest(url: url)
        request.httpMethod = endpoint.method.rawValue
        request.timeoutInterval = endpoint.timeout ?? environment.timeout

        var headers = environment.defaultHeaders.merging(endpoint.headers, strategy: .override)

        if let body = endpoint.body {
            let (data, contentType) = try body.encoded()
            request.httpBody = data
            if let contentType, headers["Content-Type"] == nil {
                headers["Content-Type"] = contentType
            }
        }

        for header in headers {
            request.setValue(header.value, forHTTPHeaderField: header.name)
        }

        return request
    }

    /// Percent-encodes a path-parameter value so it stays confined to a single URL path segment.
    /// `.urlPathAllowed` leaves `/`, `:`, `;`, `@`, `=`, `&` unescaped, so a raw value like
    /// `../admin` or `1/delete` would otherwise retarget the request. The bare-dot segment forms
    /// `.` / `..` are escaped too, since they normalize away in `URL`.
    private static func encodePathParameter(_ value: String) -> String {
        let allowed = CharacterSet.urlPathAllowed.subtracting(CharacterSet(charactersIn: "/:;=@&+$,"))
        var encoded = value.addingPercentEncoding(withAllowedCharacters: allowed) ?? value
        if encoded == "." || encoded == ".." {
            encoded = encoded.replacingOccurrences(of: ".", with: "%2E")
        }
        return encoded
    }
}
