import SwiftUI

/// Brand splash shown over the app for a beat on cold launch, matching the launch screen
/// (same logo + gradient) so the handoff from the system launch screen is seamless.
struct SplashView: View {
    var body: some View {
        LinearGradient(
            colors: [Color(red: 0.918, green: 0.345, blue: 0.047), Color(red: 0.941, green: 0.620, blue: 0.043)],
            startPoint: .bottomLeading,
            endPoint: .topTrailing
        )
        .ignoresSafeArea()
        .overlay {
            Image("BrandLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)
        }
    }
}

private struct SplashGate<Content: View>: View {
    @ViewBuilder var content: Content
    @State private var done = false

    var body: some View {
        ZStack {
            content
            if !done {
                SplashView().transition(.opacity)
            }
        }
        .task {
            try? await Task.sleep(for: .seconds(0.9))
            withAnimation(.easeOut(duration: 0.35)) { done = true }
        }
    }
}

extension View {
    /// Covers the view with ``SplashView`` on first appearance, then fades it away.
    func withSplash() -> some View { SplashGate { self } }
}
