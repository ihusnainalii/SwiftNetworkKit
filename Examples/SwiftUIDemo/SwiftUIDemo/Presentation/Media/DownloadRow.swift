import SwiftUI

struct DownloadRow: View {
    let image: RemoteImage
    let phase: DownloadPhase
    let start: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Photo #\(image.id)")
                        .font(.headline)
                    Text(image.author)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                control
            }

            ImageStage(phase: phase)
                .aspectRatio(3 / 2, contentMode: .fit)
                .frame(maxWidth: .infinity)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(.white.opacity(0.08), lineWidth: 1)
                }

            if case .failed(let message) = phase {
                Label(message, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
        .padding(14)
        .background(.background.secondary, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .animation(.smooth(duration: 0.35), value: phase.fraction)
        .animation(.smooth(duration: 0.45), value: phase.imageData != nil)
    }

    @ViewBuilder private var control: some View {
        switch phase {
        case .idle, .failed:
            Button(action: start) {
                Label("Download", systemImage: "arrow.down")
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        case .downloading(let fraction, _):
            Text(fraction > 0 ? "\(Int(fraction * 100))%" : "starting")
                .font(.caption.monospacedDigit().weight(.semibold))
                .foregroundStyle(.secondary)
        case .done:
            Button(action: start) {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
        }
    }
}

/// The tile contents for each phase. During download the blurred preview "develops" from the
/// bottom up in step with the progress fraction, then the full-resolution image fades in.
private struct ImageStage: View {
    let phase: DownloadPhase

    var body: some View {
        switch phase {
        case .idle, .failed:
            ZStack {
                LinearGradient(
                    colors: [Color(.systemGray5), Color(.systemGray6)],
                    startPoint: .top, endPoint: .bottom
                )
                Image(systemName: "photo")
                    .font(.system(size: 32, weight: .light))
                    .foregroundStyle(.tertiary)
            }

        case .downloading(let fraction, let preview):
            DevelopingImage(preview: preview.flatMap(UIImage.init(data:)), fraction: fraction)

        case .done(let data):
            if let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .transition(.opacity)
            } else {
                Color(.systemGray6)
            }
        }
    }
}

private struct DevelopingImage: View {
    let preview: UIImage?
    let fraction: Double

    var body: some View {
        GeometryReader { geo in
            ZStack {
                base
                // Sharp, saturated layer revealed from the bottom as the download progresses.
                base
                    .blur(radius: 2)
                    .saturation(1.15)
                    .mask(alignment: .bottom) {
                        Rectangle().frame(height: geo.size.height * fraction)
                    }
                // Bright waterline at the reveal edge.
                Rectangle()
                    .fill(.white.opacity(0.9))
                    .frame(height: 1.5)
                    .blur(radius: 1)
                    .position(x: geo.size.width / 2, y: geo.size.height * (1 - fraction))
                    .opacity(fraction > 0.01 && fraction < 0.99 ? 1 : 0)
            }
            .overlay {
                if fraction < 0.02 {
                    ProgressView().tint(.white)
                }
            }
        }
    }

    @ViewBuilder private var base: some View {
        if let preview {
            Image(uiImage: preview)
                .resizable()
                .scaledToFill()
                .blur(radius: 14)
                .saturation(0.55)
                .overlay(Color.black.opacity(0.12))
        } else {
            LinearGradient(
                colors: [Color(.systemGray4), Color(.systemGray6)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
        }
    }
}
