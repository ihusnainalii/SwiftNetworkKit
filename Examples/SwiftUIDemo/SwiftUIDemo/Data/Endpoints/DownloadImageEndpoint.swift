import Foundation
import SwiftNetworkKit

/// `GET https://picsum.photos/id/{id}/{w}/{h}` - a JPEG. Overrides the client's base URL per request.
struct DownloadImageEndpoint: Endpoint {
    typealias Response = Data

    enum Variant {
        /// The full-resolution photo, streamed to disk with progress.
        case full
        /// A tiny blurred placeholder that loads in one hop, shown while the full image downloads.
        case preview
    }

    let image: RemoteImage
    var variant: Variant = .full

    var baseURL: URL? { URL(string: "https://picsum.photos") }

    var path: String {
        switch variant {
        case .full:
            "/id/\(image.id)/\(image.width)/\(image.height)"
        case .preview:
            "/id/\(image.id)/32/21"
        }
    }

    var queryParameters: QueryParameters? {
        variant == .preview ? ["blur": .int(4)] : nil
    }
}
