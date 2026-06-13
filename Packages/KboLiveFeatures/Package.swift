// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "KboLiveFeatures",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "KboLiveFeatures",
            targets: ["KboLiveFeatures"]
        )
    ],
    dependencies: [
        .package(path: "../KboLiveCore"),
        .package(path: "../KboLiveDesignSystem")
    ],
    targets: [
        .target(
            name: "KboLiveFeatures",
            dependencies: [
                "KboLiveCore",
                "KboLiveDesignSystem"
            ]
        ),
        .testTarget(
            name: "KboLiveFeaturesTests",
            dependencies: ["KboLiveFeatures"]
        )
    ]
)
