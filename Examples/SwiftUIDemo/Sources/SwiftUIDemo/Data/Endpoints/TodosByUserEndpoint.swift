import Foundation
import SwiftNetworkKit

struct TodosByUserEndpoint: Endpoint {
    typealias Response = [Todo]
    let userID: Int
    var path: String { "/todos" }
    var queryParameters: QueryParameters? { ["userId": .int(userID)] }
}
