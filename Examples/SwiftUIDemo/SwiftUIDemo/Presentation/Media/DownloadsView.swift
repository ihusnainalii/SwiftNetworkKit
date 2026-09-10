import SwiftUI

struct DownloadsView: View {
    @State private var model: DownloadsViewModel

    init(container: AppContainer) {
        _model = State(wrappedValue: DownloadsViewModel(downloader: container.media))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 16) {
                    Text("Multi-megabyte JPEGs streamed straight to disk. The blurred preview loads in one hop and sharpens from the bottom up as the full image arrives.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ForEach(model.images) { image in
                        DownloadRow(image: image, phase: model.phase(for: image)) {
                            Task { await model.download(image) }
                        }
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Downloads")
        }
    }
}
