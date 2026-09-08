import SwiftUI

@main
struct SwiftUIDemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.container, .live)
        }
    }
}
