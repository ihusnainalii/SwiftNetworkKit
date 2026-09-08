import Foundation
import SwiftNetworkKit

/// An authenticated endpoint used to demo the 401 → refresh → retry flow.
struct SecretEndpoint: Endpoint {
    typealias Response = Secret
    let path = "/secret"
    var authentication: AuthRequirement { .required }
}
