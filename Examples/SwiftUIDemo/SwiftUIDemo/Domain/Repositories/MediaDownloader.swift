import Foundation

/// Downloads binary media (images) to a local file, reporting 0...1 progress as it goes.
protocol MediaDownloader: Sendable {
    /// - Parameter onProgress: called with the completed fraction (may be called from any thread).
    /// - Returns: the local file URL of the downloaded bytes.
    func download(
        _ image: RemoteImage,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL
}
