import Foundation

/// A downloadable image on picsum.photos, addressed by its stable id.
struct RemoteImage: Identifiable, Hashable, Sendable {
    let id: Int
    let width: Int
    let height: Int
    let author: String

    /// Deliberately large (multi-megabyte JPEGs) so the download progress bar is visible.
    static let samples: [RemoteImage] = [
        RemoteImage(id: 10, width: 5000, height: 3333, author: "Paul Jarvis"),
        RemoteImage(id: 24, width: 4800, height: 3200, author: "Premdodo"),
        RemoteImage(id: 42, width: 5000, height: 3333, author: "Luke Chesser"),
        RemoteImage(id: 65, width: 4600, height: 3067, author: "Vincent van Zalinge"),
        RemoteImage(id: 91, width: 5000, height: 3333, author: "Jonas Nilsson Lee"),
    ]
}
