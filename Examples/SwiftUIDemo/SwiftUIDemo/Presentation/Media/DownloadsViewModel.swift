import Foundation
import Observation
import SwiftNetworkKit

@MainActor
@Observable
final class DownloadsViewModel {
    private let downloader: any MediaDownloader

    let images = RemoteImage.samples
    private(set) var phases: [Int: DownloadPhase] = [:]

    init(downloader: any MediaDownloader) {
        self.downloader = downloader
    }

    func phase(for image: RemoteImage) -> DownloadPhase {
        phases[image.id] ?? .idle
    }

    func download(_ image: RemoteImage) async {
        phases[image.id] = .downloading(fraction: 0, preview: nil)

        // Blurred placeholder in one hop, so the tile is never empty while the full image streams.
        if let preview = await downloader.preview(for: image),
            case .downloading(let fraction, _) = phases[image.id] {
            phases[image.id] = .downloading(fraction: fraction, preview: preview)
        }

        do {
            let url = try await downloader.download(image) { [weak self] fraction in
                Task { @MainActor in
                    guard let self, case .downloading(_, let preview) = self.phases[image.id] else { return }
                    self.phases[image.id] = .downloading(fraction: fraction, preview: preview)
                }
            }
            phases[image.id] = .done(try Data(contentsOf: url))
        } catch {
            phases[image.id] = .failed(NetworkError.normalize(error).errorDescription ?? "Download failed")
        }
    }
}
