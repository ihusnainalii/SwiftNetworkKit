import versionData from "./version.json";

export const APP_VERSION = versionData.version;
export const REPO_URL = versionData.repoUrl;
export const SPM_GIT_URL = `${versionData.repoUrl}.git`;

export const getManifestSnippet = (version: string = APP_VERSION): string => `// swift-tools-version:6.0
import PackageDescription

let package = Package(
    name: "MyProject",
    platforms: [
        .iOS(.v16),
        .macOS(.v13),
        .tvOS(.v16),
        .watchOS(.v9),
        .visionOS(.v1)
    ],
    dependencies: [
        .package(url: "${SPM_GIT_URL}", from: "${version}")
    ],
    targets: [
        .target(
            name: "MyProject",
            dependencies: [
                .product(name: "SwiftNetworkKit", package: "SwiftNetworkKit")
            ]
        )
    ]
)`;

export const CLI_SNIPPET = `# Live tour hitting JSONPlaceholder API
swift run NetworkKitDemo

# Offline test suite (single-flight 401 refresh walkthrough)
swift run NetworkKitDemo --offline`;
