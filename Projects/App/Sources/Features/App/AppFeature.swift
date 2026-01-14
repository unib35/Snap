import ComposableArchitecture
import SwiftUI

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var connection: ConnectionFeature.State = .init()
        public var trackpad: TrackpadFeature.State = .init()
        public var keyboard: KeyboardFeature.State = .init()
        public var media: MediaFeature.State = .init()
        public var productivity: ProductivityFeature.State = .init()
        public var selectedTab: Tab = .trackpad
        public var isOnboarded: Bool = false
        public var isOnboardingPresented: Bool = false
        public var isConnectionSheetPresented: Bool = false
        public var isSettingsPresented: Bool = false
        public var settings: SettingsFeature.State = .init()
        public var onboarding: OnboardingFeature.State = .init()

        public init() {}
    }

    public enum Tab: String, CaseIterable, Sendable {
        case trackpad
        case keyboard
        case media
        case productivity

        public var title: String {
            switch self {
            case .trackpad: return "Trackpad"
            case .keyboard: return "Keyboard"
            case .media: return "Media"
            case .productivity: return "More"
            }
        }

        public var icon: String {
            switch self {
            case .trackpad: return "hand.tap"
            case .keyboard: return "keyboard"
            case .media: return "music.note"
            case .productivity: return "ellipsis"
            }
        }
    }

    public enum Action {
        case connection(ConnectionFeature.Action)
        case trackpad(TrackpadFeature.Action)
        case keyboard(KeyboardFeature.Action)
        case media(MediaFeature.Action)
        case productivity(ProductivityFeature.Action)
        case settings(SettingsFeature.Action)
        case onboarding(OnboardingFeature.Action)
        case tabSelected(Tab)
        case onAppear
        case checkOnboardingStatus
        case showOnboarding
        case hideOnboarding
        case completeOnboarding
        case scenePhaseChanged(ScenePhase)
        case showConnectionSheet
        case hideConnectionSheet
        case showSettings
        case hideSettings
        case handleURL(URL)
    }

    @Dependency(\.onboardingClient) var onboardingClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.connection, action: \.connection) {
            ConnectionFeature()
        }

        Scope(state: \.trackpad, action: \.trackpad) {
            TrackpadFeature()
        }

        Scope(state: \.keyboard, action: \.keyboard) {
            KeyboardFeature()
        }

        Scope(state: \.media, action: \.media) {
            MediaFeature()
        }

        Scope(state: \.productivity, action: \.productivity) {
            ProductivityFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Scope(state: \.onboarding, action: \.onboarding) {
            OnboardingFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
                // 온보딩 상태 확인 후 디바이스 검색 시작
                return .merge(
                    .send(.checkOnboardingStatus),
                    .send(.connection(.startDiscovery))
                )

            case .checkOnboardingStatus:
                let hasCompleted = onboardingClient.hasCompletedOnboarding()
                state.isOnboarded = hasCompleted
                if !hasCompleted {
                    state.isOnboardingPresented = true
                }
                return .none

            case .showOnboarding:
                state.isOnboardingPresented = true
                return .none

            case .hideOnboarding:
                state.isOnboardingPresented = false
                return .none

            case .completeOnboarding:
                state.isOnboarded = true
                state.isOnboardingPresented = false
                return .none

            case .onboarding(.completeOnboarding):
                return .send(.completeOnboarding)

            case .onboarding:
                return .none

            case .scenePhaseChanged(let phase):
                switch phase {
                case .active:
                    break
                case .background:
                    break
                default:
                    break
                }
                return .none

            case .tabSelected(let tab):
                state.selectedTab = tab
                return .none

            case .showConnectionSheet:
                state.isConnectionSheetPresented = true
                return .none

            case .hideConnectionSheet:
                state.isConnectionSheetPresented = false
                return .none

            case .showSettings:
                state.isSettingsPresented = true
                return .none

            case .hideSettings:
                state.isSettingsPresented = false
                return .none

            case .connection(.appListReceived(let apps)):
                return .send(.productivity(.appListReceived(apps)))

            case .connection(.nowPlayingInfoReceived(let info)):
                return .send(.media(.nowPlayingInfoReceived(info)))

            case .connection:
                return .none

            case .trackpad:
                return .none

            case .keyboard:
                return .none

            case .media:
                return .none

            case .productivity:
                return .none

            case .settings:
                return .none

            case .handleURL(let url):
                return handleDeepLink(url: url, state: &state)
            }
        }
    }

    // MARK: - Deep Link Handling

    private func handleDeepLink(url: URL, state: inout State) -> Effect<Action> {
        guard url.scheme == "snap" else { return .none }

        let host = url.host ?? ""
        let pathComponents = url.pathComponents.filter { $0 != "/" }

        switch host {
        case "connect":
            state.isConnectionSheetPresented = true
            return .none

        case "trackpad":
            state.selectedTab = .trackpad
            return .none

        case "keyboard":
            state.selectedTab = .keyboard
            return .none

        case "macros":
            state.selectedTab = .productivity
            return .none

        case "macro":
            // snap://macro/{uuid}
            guard let uuidString = pathComponents.first,
                  let macroId = UUID(uuidString: uuidString) else {
                return .none
            }

            state.selectedTab = .productivity

            if let macro = state.productivity.macro.macros.first(where: { $0.id == macroId }) {
                return .send(.productivity(.macro(.macroTapped(macro))))
            }
            return .none

        default:
            return .none
        }
    }
}
