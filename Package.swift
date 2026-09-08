// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "SwiftNetworkKit",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1),
    ],
    products: [
        .library(name: "SwiftNetworkKit", targets: ["SwiftNetworkKit"]),
        .executable(name: "NetworkKitDemo", targets: ["NetworkKitDemo"]),
    ],
    targets: [
        .target(
            name: "SwiftNetworkKit",
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .executableTarget(
            name: "NetworkKitDemo",
            dependencies: ["SwiftNetworkKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
        .testTarget(
            name: "SwiftNetworkKitTests",
            dependencies: ["SwiftNetworkKit"],
            swiftSettings: [.swiftLanguageMode(.v6)]
        ),
    ]
)
