import SwiftUI

@main
struct SwiftUIDemoApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(\.container, .live)
                .frame(minWidth: 480, minHeight: 640)
        }
    }
}
