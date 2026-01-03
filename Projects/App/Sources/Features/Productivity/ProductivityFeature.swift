import ComposableArchitecture
import Shared

@Reducer
public struct ProductivityFeature {
    @ObservableState
    public struct State: Equatable {
        public var isSiriActive: Bool = false
        public var runningApps: [AppInfo] = []
        public var isLoadingApps: Bool = false
        public var macro: MacroFeature.State = .init()
        public var voiceTyping: VoiceTypingFeature.State = .init()
    }

    public enum Action: Equatable, Sendable {
        // Siri
        case siriTapped
        case siriLongPressStarted
        case siriLongPressEnded
        case dictationTapped(String)

        // Window Snap
        case windowSnapTapped(WindowSnap.Position)

        // App Switcher
        case requestAppListTapped
        case appListReceived([AppInfo])
        case appTapped(AppInfo)

        // Macro
        case macro(MacroFeature.Action)

        // Voice Typing
        case voiceTyping(VoiceTypingFeature.Action)
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.macro, action: \.macro) {
            MacroFeature()
        }

        Scope(state: \.voiceTyping, action: \.voiceTyping) {
            VoiceTypingFeature()
        }

        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .siriTapped:
                state.isSiriActive.toggle()
                let isActive = state.isSiriActive
                return .run { _ in
                    await client.sendSiriCommand(
                        isActive ? .activate : .deactivate,
                        ""
                    )
                }

            case .siriLongPressStarted:
                state.isSiriActive = true
                return .run { _ in
                    await client.sendSiriCommand(.activate, "")
                }

            case .siriLongPressEnded:
                state.isSiriActive = false
                return .run { _ in
                    await client.sendSiriCommand(.deactivate, "")
                }

            case .dictationTapped(let text):
                return .run { _ in
                    await client.sendSiriCommand(.dictation, text)
                }

            case .windowSnapTapped(let position):
                return .run { _ in
                    await client.sendWindowSnap(position)
                }

            case .requestAppListTapped:
                state.isLoadingApps = true
                return .run { _ in
                    await client.requestAppList()
                }

            case .appListReceived(let apps):
                state.isLoadingApps = false
                state.runningApps = apps
                return .none

            case .appTapped(let app):
                return .run { _ in
                    await client.sendAppFocus(app.bundleID, app.pid)
                }

            case .macro:
                return .none

            case .voiceTyping:
                return .none
            }
        }
    }
}
