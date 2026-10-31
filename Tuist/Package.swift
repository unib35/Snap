// swift-tools-version: 6.0
import PackageDescription

#if TUIST
import struct ProjectDescription.PackageSettings

// Preserve the upstream availability macros when overriding OTHER_SWIFT_FLAGS.
let collectionsAvailability = [
    "5.0: macOS 10.14.4, iOS 12.2, watchOS 5.2, tvOS 12.2",
    "5.1: macOS 10.15, iOS 13.0, watchOS 6.0, tvOS 13.0",
    "5.6: macOS 12.3, iOS 15.4, watchOS 8.5, tvOS 15.4",
    "5.8: macOS 13.3, iOS 16.4, watchOS 9.4, tvOS 16.4",
    "5.9: macOS 14.0, iOS 17.0, watchOS 10.0, tvOS 17.0",
    "5.10: macOS 14.4, iOS 17.4, watchOS 10.4, tvOS 17.4, visionOS 1.1",
    "6.0: macOS 15.0, iOS 18.0, watchOS 11.0, tvOS 18.0, visionOS 2.0",
    "6.1: macOS 15.4, iOS 18.4, watchOS 11.4, tvOS 18.4, visionOS 2.4",
    "6.2: macOS 26.0, iOS 26.0, watchOS 26.0, tvOS 26.0, visionOS 26.0",
].map { "-enable-experimental-feature \"AvailabilityMacro=SwiftStdlib \($0)\"" }

let packageSettings = PackageSettings(
    productTypes: [
        "ComposableArchitecture": .framework,
    ],
    // swift-collections 1.3's Swift 6.0 manifest omits flags required by
    // its compiler(>=6.2) lifetime helpers. Keep the workaround target-local.
    targetSettings: [
        // TCA 1.23.1's BindingAction key-path comparison fails in Swift 6 mode
        // with Xcode 26.5. Its base manifest supports Swift 5 language mode.
        "ComposableArchitecture": .settings(base: [
            "SWIFT_VERSION": "5.0",
            "SWIFT_STRICT_CONCURRENCY": "complete",
        ]),
        "InternalCollectionsUtilities": .settings(base: [
            "OTHER_SWIFT_FLAGS": .array(["$(inherited)"] + collectionsAvailability + [
                "-enable-upcoming-feature MemberImportVisibility",
                "-enable-experimental-feature BuiltinModule",
                "-enable-experimental-feature Lifetimes",
                "-enable-experimental-feature InoutLifetimeDependence",
                "-enable-experimental-feature SuppressedAssociatedTypes",
            ]),
        ]),
    ]
)
#endif

let package = Package(
    name: "Snap",
    dependencies: [
        // TCA (The Composable Architecture)
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "1.17.0"),
    ]
)
