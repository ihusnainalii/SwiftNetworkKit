import Foundation
import SwiftNetworkKit

struct PostsByUserEndpoint: Endpoint {
    typealias Response = [Post]
    let userID: Int
    var path: String { "/posts" }
    var queryParameters: QueryParameters? { ["userId": .int(userID)] }
}
