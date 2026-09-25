import Foundation

extension NetworkClient {

    /// Runs `operation` with a correlation id that ``TracingInterceptor`` attaches to every request
    /// made inside it (nested calls, `async let`, task groups that inherit the task-local).
    ///
    /// ```swift
    /// try await client.withCorrelation(checkoutID) {
    ///     async let cart = client.request(GetCart())
    ///     async let user = client.request(GetUser())
    ///     return try await Receipt(cart: cart, user: user) // both carry X-Correlation-ID: <checkoutID>
    /// }
    /// ```
    #if compiler(>=6.2)
    // Swift 6.2 deprecated the isolation-parameter overload of `withValue` in favor of this one.
    public func withCorrelation<T>(
        _ id: String,
        operation: nonisolated(nonsending) () async throws -> T
    ) async rethrows -> T {
        try await TraceContext.$correlationID.withValue(id, operation: operation)
    }
    #else
    public func withCorrelation<T>(
        _ id: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        try await TraceContext.$correlationID.withValue(id, operation: operation)
    }
    #endif
}
