import Foundation

/// The lowest layer: turns a fully-formed `URLRequest` into response bytes.
///
/// This is the seam every test double and every alternative networking stack plugs into. Upload and
/// download variants (with progress) are added in milestone M7.
public protocol NetworkTransport: Sendable {
    /// Sends the request and returns the body plus the HTTP response.
    ///
    /// Implementations should map cancellation and connectivity failures to ``NetworkError``
    /// (`.cancelled`, `.timeout`, `.noInternet`) and wrap anything else as `.transport`.
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)
}
