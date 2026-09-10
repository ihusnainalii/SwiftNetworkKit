import SwiftUI

@main
struct SwiftUIDemoApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView(model: model)
                .environment(\.container, model.container)
                // Re-create the screen tree when the client is rebuilt so view models rebind.
                .id(model.settings.revision)
                .withSplash()
        }
    }
}
