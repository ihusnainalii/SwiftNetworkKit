import Foundation

/// Per-image download state for the Media screen.
enum DownloadPhase: Sendable {
    case idle
    /// Downloading: `fraction` is 0...1, `preview` is a tiny blurred placeholder once it arrives.
    case downloading(fraction: Double, preview: Data?)
    case done(Data)
    case failed(String)

    var fraction: Double? {
        if case .downloading(let value, _) = self { return value }
        return nil
    }

    var previewData: Data? {
        if case .downloading(_, let preview) = self { return preview }
        return nil
    }

    var imageData: Data? {
        if case .done(let data) = self { return data }
        return nil
    }

    var isDownloading: Bool {
        if case .downloading = self { return true }
        return false
    }
}
