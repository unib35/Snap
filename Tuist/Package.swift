// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework,
        "SwiftProtobuf": .framework,
    ]
)
#endif

let package = Package(
    name: "Snap",
    dependencies: [
        // TCA (The Composable Architecture)
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
        // Protocol Buffers
        .package(url: "https://github.com/apple/swift-protobuf", from: "1.28.0"),
    ]
)
