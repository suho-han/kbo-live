// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KboLiveDesignSystem",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "KboLiveDesignSystem",
            targets: ["KboLiveDesignSystem"]
        )
    ],
    targets: [
        .target(
            name: "KboLiveDesignSystem"
        ),
        .testTarget(
            name: "KboLiveDesignSystemTests",
            dependencies: ["KboLiveDesignSystem"]
        )
    ]
)
