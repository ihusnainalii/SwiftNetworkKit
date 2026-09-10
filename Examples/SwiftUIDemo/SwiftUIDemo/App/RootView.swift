import SwiftUI

struct RootView: View {
    let model: AppModel
    @Environment(\.container) private var container

    var body: some View {
        TabView {
            UsersListView(container: container)
                .tabItem { Label("Users", systemImage: "person.2") }

            ComposePostView(container: container)
                .tabItem { Label("Compose", systemImage: "square.and.pencil") }

            DownloadsView(container: container)
                .tabItem { Label("Downloads", systemImage: "arrow.down.circle") }

            DiagnosticsView(container: container)
                .tabItem { Label("Diagnostics", systemImage: "waveform.path.ecg") }

            SettingsView(model: model)
                .tabItem { Label("Settings", systemImage: "gearshape") }
        }
    }
}
