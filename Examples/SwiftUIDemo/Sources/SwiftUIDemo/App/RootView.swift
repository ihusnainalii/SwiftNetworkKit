import SwiftUI

struct RootView: View {
    @Environment(\.container) private var container

    var body: some View {
        TabView {
            UsersListView(container: container)
                .tabItem { Label("Users", systemImage: "person.2") }

            ComposePostView(container: container)
                .tabItem { Label("Compose", systemImage: "square.and.pencil") }

            DiagnosticsView(container: container)
                .tabItem { Label("Diagnostics", systemImage: "waveform.path.ecg") }
        }
    }
}
