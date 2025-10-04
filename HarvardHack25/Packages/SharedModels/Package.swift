// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "SharedModels",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(name: "SharedModels", targets: ["SharedModels"])
    ],
    targets: [
        .target(name: "SharedModels")
    ]
)
