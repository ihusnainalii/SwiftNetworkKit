import Foundation

/// Task-local storage for a correlation id that spans several requests in one logical operation.
/// Set it with ``NetworkClient/withCorrelation(_:operation:)``; ``TracingInterceptor`` reads it.
enum TraceContext {
    @TaskLocal static var correlationID: String?
}
