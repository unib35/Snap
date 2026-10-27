import ComposableArchitecture
import Shared
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
            case .trackpad: return String(localized: "tab.trackpad")
            case .keyboard: return String(localized: "tab.keyboard")
            case .media: return String(localized: "tab.media")
            case .productivity: return String(localized: "tab.more")
            }
        }

        public var icon: String {
            switch self {
            case .trackpad: return "hand.tap"
            case .keyboard: return "keyboard"
            case .media: return "music.note"
            case .productivity: return "square.grid.2x2"
            }
        }
    }

    @CasePathable
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
        case lowPowerModeChanged(Bool)
    }

    @Dependency(\.onboardingClient) var onboardingClient
    @Dependency(\.batteryClient) var batteryClient
    @Dependency(\.widgetClient) var widgetClient

    public init() {}

    private enum CancelID {
        case lowPowerModeObservation
    }

    public var body: some ReducerOf<Self> {
        // 자식 기능이 바꾼 상태까지 감지하도록 전체 리듀서에 onChange를 붙임
        core
            .onChange(of: { WidgetConnectionState(status: $0.connection.status) }, updateWidget(\.updateConnection))
            .onChange(of: { Self.widgetMacros(from: $0) }, updateWidget(\.updateMacros))
            .onChange(of: { WidgetNowPlaying(info: $0.media.nowPlayingInfo) }, updateWidget(\.updateNowPlaying))
    }

    @ReducerBuilder<State, Action>
    private var core: some ReducerOf<Self> {
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
                let client = batteryClient
                return .merge(
                    .send(.checkOnboardingStatus),
                    .send(.connection(.startDiscovery)),
                    .send(.connection(.startNetworkMonitoring)),
                    syncWidgets(from: state),
                    .run { send in
                        for await isLowPower in client.observeLowPowerMode() {
                            await send(.lowPowerModeChanged(isLowPower))
                        }
                    }
                )
                .cancellable(id: CancelID.lowPowerModeObservation, cancelInFlight: true)

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
                    return .merge(
                        .send(.connection(.startNetworkMonitoring)),
                        .send(.connection(.appDidBecomeActive))
                    )
                case .inactive:
                    return .send(.connection(.appWillResignActive))
                case .background:
                    return .merge(
                        .send(.connection(.appWillResignActive)),
                        .send(.connection(.stopNetworkMonitoring))
                    )
                default:
                    return .none
                }

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

            case .connection(.volumeStateReceived(let volumeState)):
                return .send(.media(.volumeStateReceived(volumeState)))

            case .connection:
                return .none

            case .trackpad(.laserPointer(.delegate(.sensitivityChanged(let sensitivity)))):
                let multiplier = LaserPointerFeature.settingsMultiplier(for: sensitivity)
                return .send(.settings(.setLaserSensitivity(multiplier)))

            case .trackpad:
                return .none

            case .keyboard:
                return .none

            case .media:
                return .none

            case .productivity:
                return .none

            case .settings(.delegate(.inputBehaviorChanged)):
                return .merge(
                    syncTrackpadSettings(from: state.settings),
                    syncLaserPointerSettings(from: state.settings)
                )

            case .settings(.delegate(.powerSavingBehaviorChanged)):
                return syncPowerSavingSettings(from: state.settings)

            case .settings:
                return .none

            case .handleURL(let url):
                return handleDeepLink(url: url, state: &state)

            case .lowPowerModeChanged(let isLowPower):
                return .send(.settings(.systemLowPowerModeChanged(isLowPower)))
            }
        }
    }

    // MARK: - Widget Sync

    /// 값이 바뀌었을 때 해당 위젯 데이터를 갱신하는 리듀서
    private func updateWidget<Value: Sendable>(
        _ update: KeyPath<WidgetClient, @Sendable (Value) async -> Void>
    ) -> (Value, Value) -> Reduce<State, Action> {
        { [widgetClient] _, newValue in
            let send = widgetClient[keyPath: update]
            return Reduce { _, _ in .run { _ in await send(newValue) } }
        }
    }

    private static func widgetMacros(from state: State) -> [WidgetMacroItem] {
        state.productivity.macro.macros.map(WidgetMacroItem.init(macro:))
    }

    /// 앱 시작 시 위젯 공유 데이터를 현재 상태로 덮어써 이전 실행의 값이 남지 않게 함
    private func syncWidgets(from state: State) -> Effect<Action> {
        let connection = WidgetConnectionState(status: state.connection.status)
        let macros = Self.widgetMacros(from: state)
        let nowPlaying = WidgetNowPlaying(info: state.media.nowPlayingInfo)
        return .run { [widgetClient] _ in
            await widgetClient.updateConnection(connection)
            await widgetClient.updateMacros(macros)
            await widgetClient.updateNowPlaying(nowPlaying)
        }
    }

    // MARK: - Deep Link Handling

    private func syncTrackpadSettings(from settings: SettingsFeature.State) -> Effect<Action> {
        .send(.trackpad(.updateSettings(
            sensitivity: settings.trackpadSensitivity,
            scrollSensitivity: settings.scrollSensitivity,
            isNaturalScrolling: settings.isNaturalScrolling,
            isTapToClick: settings.isTapToClick
        )))
    }

    private func syncLaserPointerSettings(from settings: SettingsFeature.State) -> Effect<Action> {
        let baseSensitivity = Double(LaserPointerFeature.SensitivityPreset.medium.value)
        let range = LaserPointerFeature.sensitivityRange
        let scaledSensitivity = min(max(Float(settings.laserSensitivity * baseSensitivity), range.lowerBound), range.upperBound)
        return .send(.trackpad(.laserPointer(.setSensitivity(scaledSensitivity))))
    }

    private func syncPowerSavingSettings(from settings: SettingsFeature.State) -> Effect<Action> {
        .send(.trackpad(.updatePowerSavingMode(
            isInPowerSavingMode: settings.isInPowerSavingMode,
            reducedMotionUpdateRate: settings.reducedMotionUpdateRate
        )))
    }

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
