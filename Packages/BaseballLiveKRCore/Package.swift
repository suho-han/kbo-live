// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "BaseballLiveKRCore",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "BaseballLiveKRCore",
            targets: ["BaseballLiveKRCore"]
        )
    ],
    targets: [
        .target(
            name: "BaseballLiveKRCore"
        ),
        .testTarget(
            name: "BaseballLiveKRCoreTests",
            dependencies: ["BaseballLiveKRCore"],
            resources: [
                .process("Fixtures")
            ]
        )
    ]
)
