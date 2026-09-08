import Foundation

public extension NetworkClient {

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
    func withCorrelation<T>(
        _ id: String,
        operation: () async throws -> T
    ) async rethrows -> T {
        try await TraceContext.$correlationID.withValue(id, operation: operation)
    }
}
