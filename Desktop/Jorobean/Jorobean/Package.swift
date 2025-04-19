// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "Jorobean",
    platforms: [
        .iOS(.v17)
    ],
    products: [
        .library(
            name: "Jorobean",
            targets: ["Jorobean"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "Jorobean",
            dependencies: []),
    ]
)
