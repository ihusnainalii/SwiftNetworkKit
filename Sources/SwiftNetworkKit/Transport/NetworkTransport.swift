import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// The lowest layer: turns a fully-formed `URLRequest` into response bytes.
///
/// This is the seam every test double and every alternative networking stack plugs into. Only
/// ``data(for:)`` is required — ``upload(_:from:progress:)`` and ``download(_:progress:)`` have
/// default implementations built on it (no real progress), which ``URLSessionTransport`` overrides.
public protocol NetworkTransport: Sendable {

    /// Sends the request and returns the body plus the HTTP response.
    ///
    /// Implementations should map cancellation and connectivity failures to ``NetworkError``
    /// (`.cancelled`, `.timeout`, `.noInternet`) and wrap anything else as `.transport`.
    func data(for request: URLRequest) async throws -> (Data, HTTPURLResponse)

    /// Sends `body` as the request body, reporting byte progress.
    func upload(
        _ request: URLRequest,
        from body: UploadBody,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (Data, HTTPURLResponse)

    /// Downloads the response to a temporary file, reporting byte progress. The caller owns the file.
    func download(
        _ request: URLRequest,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (URL, HTTPURLResponse)
}

extension NetworkTransport {

    public func upload(
        _ request: URLRequest,
        from body: UploadBody,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (Data, HTTPURLResponse) {
        var request = request
        let payload: Data
        switch body {
        case .data(let data):
            payload = data
        case .file(let url):
            do { payload = try Data(contentsOf: url) } catch {
                throw NetworkError.transport(underlying: asSendableError(error))
            }
        case .multipart(let form):
            do { payload = try form.encoded() } catch let error as NetworkError { throw error } catch {
                throw NetworkError.encoding(underlying: asSendableError(error))
            }
            if request.value(forHTTPHeaderField: "Content-Type") == nil {
                request.setValue(form.contentType, forHTTPHeaderField: "Content-Type")
            }
        }
        request.httpBody = payload
        let total = Int64(payload.count)
        progress?(ProgressEvent(completed: 0, total: total))
        let result = try await data(for: request)
        progress?(ProgressEvent(completed: total, total: total))
        return result
    }

    public func download(
        _ request: URLRequest,
        progress: (@Sendable (ProgressEvent) -> Void)?
    ) async throws -> (URL, HTTPURLResponse) {
        let (data, response) = try await data(for: request)
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("swiftnetworkkit-download-\(UUID().uuidString)")
        do { try data.write(to: url) } catch { throw NetworkError.transport(underlying: asSendableError(error)) }
        progress?(ProgressEvent(completed: Int64(data.count), total: Int64(data.count)))
        return (url, response)
    }
}
