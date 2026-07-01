// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BaseballLiveKRDesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "BaseballLiveKRDesignSystem",
            targets: ["BaseballLiveKRDesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "BaseballLiveKRDesignSystem"
        ),
        .testTarget(
            name: "BaseballLiveKRDesignSystemTests",
            dependencies: ["BaseballLiveKRDesignSystem"]
        )
    ]
)
