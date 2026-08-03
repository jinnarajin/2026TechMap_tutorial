// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WaterLightTutorial",
    platforms: [.visionOS(.v1), .macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/swiftlang/swift-docc-plugin",
                 from: "1.3.0")
    ],
    targets: [
        .target(name: "WaterLightTutorial")
    ]
)
