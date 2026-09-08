import Foundation

/// Per-image download state for the Media screen.
enum DownloadPhase: Sendable {
    case idle
    case downloading(Double)
    case done(Data)
    case failed(String)

    var fraction: Double? {
        if case .downloading(let value) = self { return value }
        return nil
    }

    var imageData: Data? {
        if case .done(let data) = self { return data }
        return nil
    }
}
