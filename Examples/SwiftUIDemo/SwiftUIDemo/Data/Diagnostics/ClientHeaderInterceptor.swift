import Foundation
import SwiftNetworkKit

/// Stamps every outgoing request with a client identifier. A minimal example of a `RequestInterceptor`.
struct ClientHeaderInterceptor: RequestInterceptor {
    func adapt(_ request: URLRequest, for endpoint: AnyEndpoint) async throws -> URLRequest {
        var request = request
        request.setValue("SwiftUIDemo/1.0 (iOS)", forHTTPHeaderField: "X-Client")
        return request
    }
}
