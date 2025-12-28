import ComposableArchitecture
import SwiftUI

@Reducer
public struct AppFeature {
    @ObservableState
    public struct State: Equatable {
        public var connection: ConnectionFeature.State = .init()
        public var selectedTab: Tab = .essentials
        public var isOnboarded: Bool = false
        public var isConnectionSheetPresented: Bool = false
        public var isSettingsPresented: Bool = false
        public var settings: SettingsFeature.State = .init()

        public init() {}
    }

    public enum Tab: String, CaseIterable, Sendable {
        case essentials
        case productivity
        case presenter

        public var title: String {
            switch self {
            case .essentials: return "Essentials"
            case .productivity: return "Productivity"
            case .presenter: return "Presenter"
            }
        }

        public var icon: String {
            switch self {
            case .essentials: return "hand.tap"
            case .productivity: return "square.grid.2x2"
            case .presenter: return "person.wave.2"
            }
        }
    }

    public enum Action {
        case connection(ConnectionFeature.Action)
        case settings(SettingsFeature.Action)
        case tabSelected(Tab)
        case onAppear
        case scenePhaseChanged(ScenePhase)
        case showConnectionSheet
        case hideConnectionSheet
        case showSettings
        case hideSettings
    }

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.connection, action: \.connection) {
            ConnectionFeature()
        }

        Scope(state: \.settings, action: \.settings) {
            SettingsFeature()
        }

        Reduce { state, action in
            switch action {
            case .onAppear:
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

            case .connection:
                return .none

            case .settings:
                return .none
            }
        }
    }
}

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature {
    @ObservableState
    public struct State: Equatable {
        public var trackpadSensitivity: Double = 1.0
        public var scrollSensitivity: Double = 1.0
        public var isNaturalScrolling: Bool = true
        public var isTapToClick: Bool = true
        public var isHapticEnabled: Bool = true

        public init() {}
    }

    public enum Action: Equatable {
        case setTrackpadSensitivity(Double)
        case setScrollSensitivity(Double)
        case toggleNaturalScrolling
        case toggleTapToClick
        case toggleHaptic
        case resetToDefaults
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .setTrackpadSensitivity(let value):
                state.trackpadSensitivity = value
                return .none

            case .setScrollSensitivity(let value):
                state.scrollSensitivity = value
                return .none

            case .toggleNaturalScrolling:
                state.isNaturalScrolling.toggle()
                return .none

            case .toggleTapToClick:
                state.isTapToClick.toggle()
                return .none

            case .toggleHaptic:
                state.isHapticEnabled.toggle()
                return .none

            case .resetToDefaults:
                state = State()
                return .none
            }
        }
    }
}
