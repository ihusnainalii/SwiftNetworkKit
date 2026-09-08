/// Reasons the default ``Endpoint`` decoder cannot produce a value.
public enum EndpointDecodingFailure: Error, Sendable, Equatable {
    case responseNotUTF8
    case unsupportedResponseType(String)
}
