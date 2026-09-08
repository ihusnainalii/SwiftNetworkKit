import Foundation

/// Inspects a response before status mapping and decoding. Runs in **reverse** order of
/// ``NetworkConfiguration/responseInterceptors`` (middleware semantics: last in wraps closest to the
/// transport).
///
/// Use to translate app-specific error envelopes, trigger a re-auth challenge, or serve a canned body.
public protocol ResponseInterceptor: Sendable {
    func process(_ context: ResponseContext, for endpoint: AnyEndpoint) async throws -> InterceptOutcome
}
