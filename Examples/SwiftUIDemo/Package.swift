// swift-tools-version:6.0
import PackageDescription

// A standalone SwiftUI app that consumes SwiftNetworkKit via a local path dependency.
// Runs on macOS with `swift run SwiftUIDemo`; the same sources build for iOS in Xcode.
let package = Package(
    name: "SwiftUIDemo",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
    ],
    dependencies: [
        .package(path: "../.."),
    ],
    targets: [
        .executableTarget(
            name: "SwiftUIDemo",
            dependencies: [
                .product(name: "SwiftNetworkKit", package: "SwiftNetworkKit"),
            ],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
