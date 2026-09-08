import Foundation
import SwiftNetworkKit

/// `GET https://picsum.photos/id/{id}/{w}/{h}` — a JPEG. Overrides the client's base URL per request.
struct DownloadImageEndpoint: Endpoint {
    typealias Response = Data
    let image: RemoteImage

    var baseURL: URL? { URL(string: "https://picsum.photos") }
    var path: String { "/id/\(image.id)/\(image.width)/\(image.height)" }
}
