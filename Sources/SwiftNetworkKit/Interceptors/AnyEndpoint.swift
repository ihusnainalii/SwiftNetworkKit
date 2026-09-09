import Foundation

#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// A type-erased ``Endpoint``: the metadata an interceptor, logger or registry needs, plus a
/// `@Sendable` decode thunk, without the `associatedtype Response` that blocks heterogeneous storage.
///
/// The public ``NetworkClient/request(_:)`` stays generic — this only appears at the interceptor and
/// (later) batch/queue seams.
public struct AnyEndpoint: Sendable {
    public let method: HTTPMethod
    public let path: String
    public let baseURL: URL?
    public let headers: HTTPHeaders
    public let authentication: AuthRequirement
    public let priority: RequestPriority

    /// Decodes response bytes exactly as the original endpoint would, returning its erased `Response`.
    let decodeThunk: @Sendable (Data, HTTPURLResponse, JSONDecoder) throws -> any Sendable

    public init<E: Endpoint>(_ endpoint: E) {
        self.method = endpoint.method
        self.path = endpoint.path
        self.baseURL = endpoint.baseURL
        self.headers = endpoint.headers
        self.authentication = endpoint.authentication
        self.priority = endpoint.priority
        self.decodeThunk = { data, response, decoder in
            try endpoint.decode(data, response: response, using: decoder)
        }
    }

    /// Decodes with the erased endpoint's own logic.
    public func decode(_ data: Data, response: HTTPURLResponse, using decoder: JSONDecoder) throws -> any Sendable {
        try decodeThunk(data, response, decoder)
    }
}
