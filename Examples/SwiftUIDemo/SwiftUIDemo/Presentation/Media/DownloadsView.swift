import SwiftUI

struct DownloadsView: View {
    @State private var model: DownloadsViewModel

    init(container: AppContainer) {
        _model = State(wrappedValue: DownloadsViewModel(downloader: container.media))
    }

    var body: some View {
        NavigationStack {
            List(model.images) { image in
                DownloadRow(image: image, phase: model.phase(for: image)) {
                    Task { await model.download(image) }
                }
            }
            .navigationTitle("Downloads")
            .listStyle(.plain)
        }
    }
}
