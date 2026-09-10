import Foundation
import SwiftNetworkKit

struct LiveMediaDownloader: MediaDownloader {
    let client: NetworkClient

    func preview(for image: RemoteImage) async -> Data? {
        try? await client.data(for: DownloadImageEndpoint(image: image, variant: .preview))
    }

    func download(
        _ image: RemoteImage,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL {
        let destination = FileManager.default.temporaryDirectory
            .appendingPathComponent("picsum-\(image.id).jpg")

        return try await client.download(DownloadImageEndpoint(image: image), to: destination) { event in
            if let fraction = event.fraction { onProgress(fraction) }
        }
    }
}
