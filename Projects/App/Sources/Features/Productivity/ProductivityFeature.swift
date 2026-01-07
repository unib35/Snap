import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct ProductivityFeature {
    @ObservableState
    public struct State: Equatable {
        public var isSiriActive: Bool = false
        public var runningApps: [AppInfo] = []
        public var isLoadingApps: Bool = false
        public var isAppSwitcherEditing: Bool = false
        public var appOrder: [String] = []  // bundleID 순서
        public var macro: MacroFeature.State = .init()
        public var voiceTyping: VoiceTypingFeature.State = .init()
        public var presenter: PresenterFeature.State = .init()
        public var shortsRemote: ShortsRemoteFeature.State = .init()
        public var quickLaunch: QuickLaunchFeature.State = .init()

        /// 저장된 순서에 따라 정렬된 앱 목록
        public var sortedApps: [AppInfo] {
            if appOrder.isEmpty {
                return runningApps
            }
            return runningApps.sorted { app1, app2 in
                let index1 = appOrder.firstIndex(of: app1.bundleID) ?? Int.max
                let index2 = appOrder.firstIndex(of: app2.bundleID) ?? Int.max
                return index1 < index2
            }
        }
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
        case toggleAppSwitcherEditMode
        case appMoved(from: IndexSet, to: Int)
        case loadAppOrder
        case saveAppOrder

        // Macro
        case macro(MacroFeature.Action)

        // Voice Typing
        case voiceTyping(VoiceTypingFeature.Action)

        // Presenter
        case presenter(PresenterFeature.Action)

        // Shorts Remote
        case shortsRemote(ShortsRemoteFeature.Action)

        // Quick Launch
        case quickLaunch(QuickLaunchFeature.Action)
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

        Scope(state: \.presenter, action: \.presenter) {
            PresenterFeature()
        }

        Scope(state: \.shortsRemote, action: \.shortsRemote) {
            ShortsRemoteFeature()
        }

        Scope(state: \.quickLaunch, action: \.quickLaunch) {
            QuickLaunchFeature()
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

            case .toggleAppSwitcherEditMode:
                state.isAppSwitcherEditing.toggle()
                return .none

            case .appMoved(let from, let to):
                var sortedApps = state.sortedApps
                sortedApps.move(fromOffsets: from, toOffset: to)
                state.appOrder = sortedApps.map { $0.bundleID }
                return .send(.saveAppOrder)

            case .loadAppOrder:
                if let data = UserDefaults.standard.data(forKey: "snap.appSwitcher.order"),
                   let order = try? JSONDecoder().decode([String].self, from: data) {
                    state.appOrder = order
                }
                return .none

            case .saveAppOrder:
                if let data = try? JSONEncoder().encode(state.appOrder) {
                    UserDefaults.standard.set(data, forKey: "snap.appSwitcher.order")
                }
                return .none

            case .macro:
                return .none

            case .voiceTyping:
                return .none

            case .presenter:
                return .none

            case .shortsRemote:
                return .none

            case .quickLaunch:
                return .none
            }
        }
    }
}
