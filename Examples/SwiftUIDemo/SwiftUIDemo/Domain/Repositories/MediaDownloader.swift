import Foundation

/// Downloads binary media (images) to a local file, reporting 0...1 progress as it goes.
protocol MediaDownloader: Sendable {
    /// A tiny blurred placeholder, fetched in one hop. Best effort: returns `nil` if it fails,
    /// so the caller can still show the progress fill without a preview.
    func preview(for image: RemoteImage) async -> Data?

    /// - Parameter onProgress: called with the completed fraction (may be called from any thread).
    /// - Returns: the local file URL of the downloaded bytes.
    func download(
        _ image: RemoteImage,
        onProgress: @escaping @Sendable (Double) -> Void
    ) async throws -> URL
}
