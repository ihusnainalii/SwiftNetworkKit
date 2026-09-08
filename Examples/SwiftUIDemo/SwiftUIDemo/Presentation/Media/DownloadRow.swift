import SwiftUI

struct DownloadRow: View {
    let image: RemoteImage
    let phase: DownloadPhase
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Photo #\(image.id)").font(.headline)
                    Text(image.author).font(.caption).foregroundStyle(.secondary)
                }
                Spacer()
                control
            }

            switch phase {
            case .downloading(let fraction):
                ProgressView(value: fraction) {
                    Text("\(Int(fraction * 100))%").font(.caption2).monospacedDigit()
                }
            case .done(let data):
                if let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 160)
                        .clipped()
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            case .failed(let message):
                Label(message, systemImage: "exclamationmark.triangle")
                    .font(.caption).foregroundStyle(.red)
            case .idle:
                EmptyView()
            }
        }
        .padding(.vertical, 6)
    }

    @ViewBuilder private var control: some View {
        switch phase {
        case .idle, .failed:
            Button("Download", action: start).buttonStyle(.bordered)
        case .downloading:
            ProgressView()
        case .done:
            Button(action: start) { Image(systemName: "arrow.clockwise") }.buttonStyle(.bordered)
        }
    }
}
