import ProjectDescription

// MARK: - Project

let project = Project(
    name: "Snap",
    options: .options(
        defaultKnownRegions: ["en", "ko"],
        developmentRegion: "ko"
    ),
    settings: .settings(
        base: [
            "SWIFT_VERSION": "6.0",
            "ENABLE_USER_SCRIPT_SANDBOXING": "NO",
        ],
        configurations: [
            .debug(name: "Debug"),
            .release(name: "Release"),
        ]
    ),
    targets: [
        // MARK: - Shared (Framework)
        .target(
            name: "Shared",
            destinations: [.iPhone, .iPad, .mac],
            product: .framework,
            bundleId: "com.snap.shared",
            deploymentTargets: .multiplatform(iOS: "17.0", macOS: "14.0"),
            sources: ["Projects/Shared/Sources/**"],
            resources: ["Projects/Shared/Resources/**"],
            dependencies: [
                .external(name: "SwiftProtobuf"),
            ]
        ),

        // MARK: - App (iOS)
        .target(
            name: "App",
            destinations: [.iPhone, .iPad],
            product: .app,
            bundleId: "com.snap.app",
            deploymentTargets: .iOS("17.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Snap",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "UILaunchScreen": [:],
                "UISupportedInterfaceOrientations": ["UIInterfaceOrientationPortrait"],
                "NSLocalNetworkUsageDescription": "Snap uses local network to connect to your Mac.",
                "NSBonjourServices": ["_snap._tcp.", "_snap._udp."],
                "NSSpeechRecognitionUsageDescription": "Snap uses speech recognition for voice typing.",
                "NSMicrophoneUsageDescription": "Snap uses microphone for voice typing.",
            ]),
            sources: ["Projects/App/Sources/**"],
            resources: ["Projects/App/Resources/**"],
            dependencies: [
                .target(name: "Shared"),
                .external(name: "ComposableArchitecture"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "",
                    "CODE_SIGN_STYLE": "Automatic",
                ]
            )
        ),

        // MARK: - App Tests
        .target(
            name: "AppTests",
            destinations: [.iPhone, .iPad],
            product: .unitTests,
            bundleId: "com.snap.app.tests",
            deploymentTargets: .iOS("17.0"),
            sources: ["Projects/App/Tests/**"],
            dependencies: [
                .target(name: "App"),
            ]
        ),

        // MARK: - MacReceiver (macOS)
        .target(
            name: "MacReceiver",
            destinations: [.mac],
            product: .app,
            bundleId: "com.snap.receiver",
            deploymentTargets: .macOS("14.0"),
            infoPlist: .extendingDefault(with: [
                "CFBundleDisplayName": "Snap Receiver",
                "CFBundleShortVersionString": "1.0.0",
                "CFBundleVersion": "1",
                "LSUIElement": false,
                "NSLocalNetworkUsageDescription": "Snap Receiver uses local network to receive commands from iOS.",
                "NSBonjourServices": ["_snap._tcp.", "_snap._udp."],
            ]),
            sources: ["Projects/MacReceiver/Sources/**"],
            resources: ["Projects/MacReceiver/Resources/**"],
            entitlements: .file(path: "Projects/MacReceiver/MacReceiver.entitlements"),
            dependencies: [
                .target(name: "Shared"),
            ],
            settings: .settings(
                base: [
                    "DEVELOPMENT_TEAM": "",
                    "CODE_SIGN_STYLE": "Automatic",
                ]
            )
        ),

        // MARK: - MacReceiver Tests
        .target(
            name: "MacReceiverTests",
            destinations: [.mac],
            product: .unitTests,
            bundleId: "com.snap.receiver.tests",
            deploymentTargets: .macOS("14.0"),
            sources: ["Projects/MacReceiver/Tests/**"],
            dependencies: [
                .target(name: "MacReceiver"),
            ]
        ),
    ],
    schemes: [
        .scheme(
            name: "App",
            shared: true,
            buildAction: .buildAction(targets: ["App"]),
            testAction: .targets(["AppTests"]),
            runAction: .runAction(configuration: "Debug", executable: "App")
        ),
        .scheme(
            name: "MacReceiver",
            shared: true,
            buildAction: .buildAction(targets: ["MacReceiver"]),
            testAction: .targets(["MacReceiverTests"]),
            runAction: .runAction(configuration: "Debug", executable: "MacReceiver")
        ),
    ]
)
