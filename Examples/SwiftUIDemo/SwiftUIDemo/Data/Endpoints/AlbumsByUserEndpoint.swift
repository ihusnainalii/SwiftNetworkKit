import Foundation
import SwiftNetworkKit

struct AlbumsByUserEndpoint: Endpoint {
    typealias Response = [Album]
    let userID: Int
    var path: String { "/albums" }
    var queryParameters: QueryParameters? { ["userId": .int(userID)] }
}
