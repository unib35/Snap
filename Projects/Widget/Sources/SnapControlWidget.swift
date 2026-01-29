import AppIntents
import SwiftUI
import WidgetKit

// MARK: - Connection Toggle Intent (iOS 18+)

/// Control Center에서 연결 상태를 토글하는 AppIntent
@available(iOS 18.0, *)
struct ToggleConnectionIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Snap 연결 토글"
    static let description = IntentDescription("Mac과의 연결을 토글합니다.")

    @Parameter(title: "연결됨")
    var value: Bool

    init() {
        self.value = WidgetDataManager.isConnected
    }

    init(value: Bool) {
        self.value = value
    }

    func perform() async throws -> some IntentResult {
        // The toggle action is handled through URL scheme when the control is tapped
        // Widget extensions can't directly control app state
        .result()
    }
}

// MARK: - Connection Value Provider (iOS 18+)

@available(iOS 18.0, *)
struct ConnectionValueProvider: ControlValueProvider {
    var previewValue: Bool {
        false
    }

    func currentValue() async throws -> Bool {
        WidgetDataManager.isConnected
    }
}

// MARK: - Snap Control Widget (iOS 18+)

/// Control Center에 표시되는 연결 토글 컨트롤
@available(iOS 18.0, *)
struct SnapControlWidget: ControlWidget {
    static let kind: String = "com.snap.app.control"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind,
            provider: ConnectionValueProvider()
        ) { isConnected in
            ControlWidgetToggle(
                "Snap",
                isOn: isConnected,
                action: ToggleConnectionIntent(value: !isConnected)
            ) { isOn in
                Label(
                    isOn ? "연결됨" : "연결 안됨",
                    systemImage: isOn ? "wifi" : "wifi.slash"
                )
            }
            .tint(.green)
        }
        .displayName("Snap 연결")
        .description("Mac과의 연결을 토글합니다.")
    }
}

// MARK: - Trackpad Control Widget (iOS 18+)

/// Control Center에서 트랙패드를 바로 여는 버튼
@available(iOS 18.0, *)
struct TrackpadControlIntent: AppIntent {
    static let title: LocalizedStringResource = "트랙패드 열기"
    static let description = IntentDescription("Snap 트랙패드를 엽니다.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        // URL is a compile-time constant, so it's always valid
        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "snap://trackpad")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}

@available(iOS 18.0, *)
struct TrackpadControlWidget: ControlWidget {
    static let kind: String = "com.snap.app.control.trackpad"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: TrackpadControlIntent()) {
                Label("트랙패드", systemImage: "hand.draw")
            }
        }
        .displayName("트랙패드")
        .description("Snap 트랙패드를 엽니다.")
    }
}

// MARK: - Keyboard Control Widget (iOS 18+)

/// Control Center에서 키보드를 바로 여는 버튼
@available(iOS 18.0, *)
struct KeyboardControlIntent: AppIntent {
    static let title: LocalizedStringResource = "키보드 열기"
    static let description = IntentDescription("Snap 키보드를 엽니다.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        // URL is a compile-time constant, so it's always valid
        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "snap://keyboard")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}

@available(iOS 18.0, *)
struct KeyboardControlWidget: ControlWidget {
    static let kind: String = "com.snap.app.control.keyboard"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: KeyboardControlIntent()) {
                Label("키보드", systemImage: "keyboard")
            }
        }
        .displayName("키보드")
        .description("Snap 키보드를 엽니다.")
    }
}

// MARK: - Media Control Widget (iOS 18+)

/// Control Center에서 미디어 컨트롤을 여는 버튼
@available(iOS 18.0, *)
struct MediaControlButtonIntent: AppIntent {
    static let title: LocalizedStringResource = "미디어 컨트롤 열기"
    static let description = IntentDescription("Snap 미디어 컨트롤을 엽니다.")
    static let openAppWhenRun: Bool = true

    func perform() async throws -> some IntentResult & OpensIntent {
        // URL is a compile-time constant, so it's always valid
        // swiftlint:disable:next force_unwrapping
        let url = URL(string: "snap://media")!
        return .result(opensIntent: OpenURLIntent(url))
    }
}

@available(iOS 18.0, *)
struct MediaControlControlWidget: ControlWidget {
    static let kind: String = "com.snap.app.control.media"

    var body: some ControlWidgetConfiguration {
        StaticControlConfiguration(
            kind: Self.kind
        ) {
            ControlWidgetButton(action: MediaControlButtonIntent()) {
                Label("미디어", systemImage: "music.note")
            }
        }
        .displayName("미디어 컨트롤")
        .description("Mac 미디어 컨트롤을 엽니다.")
    }
}
