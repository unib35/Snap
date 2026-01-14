import ComposableArchitecture
import SwiftUI

// MARK: - Settings Client

public struct SettingsClient: Sendable {
    public var load: @Sendable () -> SettingsFeature.State
    public var save: @Sendable (SettingsFeature.State) -> Void
}

extension SettingsClient: DependencyKey {
    public static var liveValue: SettingsClient {
        SettingsClient(
            load: {
                let defaults = UserDefaults.standard
                return SettingsFeature.State(
                    trackpadSensitivity: defaults.double(forKey: "trackpadSensitivity").nonZeroOrDefault(1.0),
                    scrollSensitivity: defaults.double(forKey: "scrollSensitivity").nonZeroOrDefault(1.0),
                    laserSensitivity: defaults.double(forKey: "laserSensitivity").nonZeroOrDefault(1.0),
                    isNaturalScrolling: defaults.object(forKey: "isNaturalScrolling") as? Bool ?? true,
                    isTapToClick: defaults.object(forKey: "isTapToClick") as? Bool ?? true,
                    hapticIntensity: HapticIntensity(rawValue: defaults.integer(forKey: "hapticIntensity")) ?? .medium,
                    accentColor: AccentColor(rawValue: defaults.integer(forKey: "accentColor")) ?? .blue
                )
            },
            save: { state in
                let defaults = UserDefaults.standard
                defaults.set(state.trackpadSensitivity, forKey: "trackpadSensitivity")
                defaults.set(state.scrollSensitivity, forKey: "scrollSensitivity")
                defaults.set(state.laserSensitivity, forKey: "laserSensitivity")
                defaults.set(state.isNaturalScrolling, forKey: "isNaturalScrolling")
                defaults.set(state.isTapToClick, forKey: "isTapToClick")
                defaults.set(state.hapticIntensity.rawValue, forKey: "hapticIntensity")
                defaults.set(state.accentColor.rawValue, forKey: "accentColor")
            }
        )
    }

    public static var testValue: SettingsClient {
        SettingsClient(
            load: { .init() },
            save: { _ in }
        )
    }
}

public extension DependencyValues {
    var settingsClient: SettingsClient {
        get { self[SettingsClient.self] }
        set { self[SettingsClient.self] = newValue }
    }
}

private extension Double {
    func nonZeroOrDefault(_ defaultValue: Double) -> Double {
        self == 0 ? defaultValue : self
    }
}

// MARK: - Types

public enum HapticIntensity: Int, CaseIterable, Sendable {
    case off = 0
    case light = 1
    case medium = 2
    case strong = 3

    public var title: String {
        switch self {
        case .off: return String(localized: "haptic.off")
        case .light: return String(localized: "haptic.light")
        case .medium: return String(localized: "haptic.medium")
        case .strong: return String(localized: "haptic.strong")
        }
    }
}

public enum AccentColor: Int, CaseIterable, Sendable {
    case blue = 0
    case purple = 1
    case pink = 2
    case red = 3
    case orange = 4
    case yellow = 5
    case green = 6
    case teal = 7

    public var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        }
    }

    public var title: String {
        switch self {
        case .blue: return String(localized: "color.blue")
        case .purple: return String(localized: "color.purple")
        case .pink: return String(localized: "color.pink")
        case .red: return String(localized: "color.red")
        case .orange: return String(localized: "color.orange")
        case .yellow: return String(localized: "color.yellow")
        case .green: return String(localized: "color.green")
        case .teal: return String(localized: "color.teal")
        }
    }
}

// MARK: - SettingsFeature

@Reducer
public struct SettingsFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        // Sensitivity
        public var trackpadSensitivity: Double = 1.0
        public var scrollSensitivity: Double = 1.0
        public var laserSensitivity: Double = 1.0

        // Trackpad Options
        public var isNaturalScrolling: Bool = true
        public var isTapToClick: Bool = true

        // Haptic
        public var hapticIntensity: HapticIntensity = .medium

        // Appearance
        public var accentColor: AccentColor = .blue

        public var isHapticEnabled: Bool {
            hapticIntensity != .off
        }

        public init(
            trackpadSensitivity: Double = 1.0,
            scrollSensitivity: Double = 1.0,
            laserSensitivity: Double = 1.0,
            isNaturalScrolling: Bool = true,
            isTapToClick: Bool = true,
            hapticIntensity: HapticIntensity = .medium,
            accentColor: AccentColor = .blue
        ) {
            self.trackpadSensitivity = trackpadSensitivity
            self.scrollSensitivity = scrollSensitivity
            self.laserSensitivity = laserSensitivity
            self.isNaturalScrolling = isNaturalScrolling
            self.isTapToClick = isTapToClick
            self.hapticIntensity = hapticIntensity
            self.accentColor = accentColor
        }
    }

    public enum Action: Equatable, Sendable {
        // Lifecycle
        case onAppear
        case save

        // Sensitivity
        case setTrackpadSensitivity(Double)
        case setScrollSensitivity(Double)
        case setLaserSensitivity(Double)

        // Trackpad Options
        case toggleNaturalScrolling
        case toggleTapToClick

        // Haptic
        case setHapticIntensity(HapticIntensity)

        // Appearance
        case setAccentColor(AccentColor)

        // Reset
        case resetToDefaults
    }

    @Dependency(\.settingsClient) var settingsClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .onAppear:
                state = settingsClient.load()
                return .none

            case .save:
                let currentState = state
                let client = settingsClient
                return .run { _ in
                    client.save(currentState)
                }

            case .setTrackpadSensitivity(let value):
                state.trackpadSensitivity = value
                return .send(.save)

            case .setScrollSensitivity(let value):
                state.scrollSensitivity = value
                return .send(.save)

            case .setLaserSensitivity(let value):
                state.laserSensitivity = value
                return .send(.save)

            case .toggleNaturalScrolling:
                state.isNaturalScrolling.toggle()
                return .send(.save)

            case .toggleTapToClick:
                state.isTapToClick.toggle()
                return .send(.save)

            case .setHapticIntensity(let intensity):
                state.hapticIntensity = intensity
                return .send(.save)

            case .setAccentColor(let color):
                state.accentColor = color
                return .send(.save)

            case .resetToDefaults:
                state = State()
                return .send(.save)
            }
        }
    }
}
