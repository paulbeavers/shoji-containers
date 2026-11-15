// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ShojiContainers",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "shoji-containers", targets: ["ShojiContainers"])
    ],
    targets: [
        .executableTarget(name: "ShojiContainers", path: "Sources/ShojiContainers")
    ]
)
