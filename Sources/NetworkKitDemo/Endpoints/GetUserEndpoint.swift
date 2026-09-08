import Foundation
import SwiftNetworkKit

struct GetUserEndpoint: Endpoint {
    typealias Response = User
    let id: Int
    var path: String { "/users/:id" }
    var pathParameters: [String: String] { ["id": String(id)] }
}
