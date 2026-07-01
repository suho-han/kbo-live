// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BaseballLiveKRFeatures",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "BaseballLiveKRFeatures",
            targets: ["BaseballLiveKRFeatures"]
        )
    ],
    dependencies: [
        .package(path: "../BaseballLiveKRCore"),
        .package(path: "../BaseballLiveKRDesignSystem")
    ],
    targets: [
        .target(
            name: "BaseballLiveKRFeatures",
            dependencies: [
                "BaseballLiveKRCore",
                "BaseballLiveKRDesignSystem"
            ]
        ),
        .testTarget(
            name: "BaseballLiveKRFeaturesTests",
            dependencies: ["BaseballLiveKRFeatures"]
        )
    ]
)
