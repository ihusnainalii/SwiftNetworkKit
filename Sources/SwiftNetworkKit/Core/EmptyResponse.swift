/// A response body that is expected to be empty (204, or a write with no useful payload).
public struct EmptyResponse: Codable, Sendable, Hashable {
    public init() {}
}
