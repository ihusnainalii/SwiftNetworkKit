import Foundation
import SwiftNetworkKit

/// Always 404s — used to demo error handling.
struct MissingUserEndpoint: Endpoint {
    typealias Response = User
    var path: String { "/users/999999" }
}
