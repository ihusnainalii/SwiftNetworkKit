import Foundation
import SwiftNetworkKit

struct ListPostsEndpoint: Endpoint {
    typealias Response = [Post]
    var authorUserID: Int?
    var path: String { "/posts" }
    var queryParameters: QueryParameters? {
        guard let authorUserID else { return nil }
        return ["userId": .int(authorUserID)]
    }
}
