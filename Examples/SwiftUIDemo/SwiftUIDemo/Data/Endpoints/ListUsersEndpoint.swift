import Foundation
import SwiftNetworkKit

struct ListUsersEndpoint: Endpoint {
    typealias Response = [User]
    var path: String { "/users" }
}
