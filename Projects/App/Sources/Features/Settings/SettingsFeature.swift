import ComposableArchitecture
@preconcurrency import Foundation
import Shared
import SwiftUI

// MARK: - Settings Client

public struct SettingsClient: Sendable {
    public var load: @Sendable () -> SettingsFeature.State
    public var save: @Sendable (SettingsFeature.State) -> Void
    public var loadFromiCloud: @Sendable () -> CodableSettings?
    public var saveToiCloud: @Sendable (CodableSettings) -> Void
    public var isiCloudAvailable: @Sendable () -> Bool
    public var observeiCloudChanges: @Sendable () -> AsyncStream<Void>
}

extension SettingsClient: DependencyKey {
    public static var liveValue: SettingsClient {
        let iCloudPersistence = iCloudPersistence.shared

        return SettingsClient(
            load: {
                let defaults = UserDefaults.standard
                return SettingsFeature.State(
                    trackpadSensitivity: defaults.double(forKey: "trackpadSensitivity").nonZeroOrDefault(1.0),
                    scrollSensitivity: defaults.double(forKey: "scrollSensitivity").nonZeroOrDefault(1.0),
                    laserSensitivity: defaults.double(forKey: "laserSensitivity").nonZeroOrDefault(1.0),
                    isNaturalScrolling: defaults.object(forKey: "isNaturalScrolling") as? Bool ?? true,
                    isTapToClick: defaults.object(forKey: "isTapToClick") as? Bool ?? true,
                    hapticIntensity: HapticIntensity(rawValue: defaults.integer(forKey: "hapticIntensity")) ?? .medium,
                    accentColor: AccentColor(rawValue: defaults.integer(forKey: "accentColor")) ?? .blue,
                    isBatteryOptimizationEnabled: defaults.bool(forKey: "isBatteryOptimizationEnabled"),
                    autoDetectLowPowerMode: defaults.object(forKey: "autoDetectLowPowerMode") as? Bool ?? true,
                    reducedMotionUpdateRate: defaults.object(forKey: "reducedMotionUpdateRate") as? Bool ?? true,
                    reducedAnimations: defaults.object(forKey: "reducedAnimations") as? Bool ?? true,
                    iCloudSyncEnabled: defaults.object(forKey: "iCloudSyncEnabled") as? Bool ?? false
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
                defaults.set(state.isBatteryOptimizationEnabled, forKey: "isBatteryOptimizationEnabled")
                defaults.set(state.autoDetectLowPowerMode, forKey: "autoDetectLowPowerMode")
                defaults.set(state.reducedMotionUpdateRate, forKey: "reducedMotionUpdateRate")
                defaults.set(state.reducedAnimations, forKey: "reducedAnimations")
                defaults.set(state.iCloudSyncEnabled, forKey: "iCloudSyncEnabled")
            },
            loadFromiCloud: {
                iCloudPersistence.load(forKey: "settings") as CodableSettings?
            },
            saveToiCloud: { codableSettings in
                iCloudPersistence.save(codableSettings, forKey: "settings")
            },
            isiCloudAvailable: {
                iCloudPersistence.isAvailable
            },
            observeiCloudChanges: {
                AsyncStream { continuation in
                    let observer = NotificationCenter.default.addObserver(
                        forName: .iCloudSettingsDidChange,
                        object: nil,
                        queue: .main
                    ) { _ in
                        continuation.yield(())
                    }

                    continuation.onTermination = { @Sendable _ in
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
        )
    }

    public static var testValue: SettingsClient {
        SettingsClient(
            load: { .init() },
            save: { _ in },
            loadFromiCloud: { nil },
            saveToiCloud: { _ in },
            isiCloudAvailable: { true },
            observeiCloudChanges: { .finished }
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

public enum HapticIntensity: Int, CaseIterable, Sendable, Codable {
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

public enum AccentColor: Int, CaseIterable, Sendable, Codable {
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

// MARK: - CodableSettings (iCloud 동기화용)

/// iCloud 동기화를 위한 Codable 설정 구조체
public struct CodableSettings: Codable, Sendable, Equatable {
    public var trackpadSensitivity: Double
    public var scrollSensitivity: Double
    public var laserSensitivity: Double
    public var isNaturalScrolling: Bool
    public var isTapToClick: Bool
    public var hapticIntensity: HapticIntensity
    public var accentColor: AccentColor
    public var isBatteryOptimizationEnabled: Bool
    public var autoDetectLowPowerMode: Bool
    public var reducedMotionUpdateRate: Bool
    public var reducedAnimations: Bool
    public var iCloudSyncEnabled: Bool

    public init(from state: SettingsFeature.State) {
        self.trackpadSensitivity = state.trackpadSensitivity
        self.scrollSensitivity = state.scrollSensitivity
        self.laserSensitivity = state.laserSensitivity
        self.isNaturalScrolling = state.isNaturalScrolling
        self.isTapToClick = state.isTapToClick
        self.hapticIntensity = state.hapticIntensity
        self.accentColor = state.accentColor
        self.isBatteryOptimizationEnabled = state.isBatteryOptimizationEnabled
        self.autoDetectLowPowerMode = state.autoDetectLowPowerMode
        self.reducedMotionUpdateRate = state.reducedMotionUpdateRate
        self.reducedAnimations = state.reducedAnimations
        self.iCloudSyncEnabled = state.iCloudSyncEnabled
    }

    public func toState() -> SettingsFeature.State {
        SettingsFeature.State(
            trackpadSensitivity: trackpadSensitivity,
            scrollSensitivity: scrollSensitivity,
            laserSensitivity: laserSensitivity,
            isNaturalScrolling: isNaturalScrolling,
            isTapToClick: isTapToClick,
            hapticIntensity: hapticIntensity,
            accentColor: accentColor,
            isBatteryOptimizationEnabled: isBatteryOptimizationEnabled,
            autoDetectLowPowerMode: autoDetectLowPowerMode,
            reducedMotionUpdateRate: reducedMotionUpdateRate,
            reducedAnimations: reducedAnimations,
            iCloudSyncEnabled: iCloudSyncEnabled
        )
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

        // Battery Optimization
        public var isBatteryOptimizationEnabled: Bool = false
        public var autoDetectLowPowerMode: Bool = true
        public var isSystemLowPowerModeActive: Bool = false
        public var reducedMotionUpdateRate: Bool = true
        public var reducedAnimations: Bool = true

        // iCloud Sync
        public var iCloudSyncEnabled: Bool = false
        public var isiCloudAvailable: Bool = false

        public var isHapticEnabled: Bool {
            hapticIntensity != .off
        }

        /// 현재 배터리 절약 모드가 활성화되어 있는지 (수동 또는 자동)
        public var isInPowerSavingMode: Bool {
            isBatteryOptimizationEnabled || (autoDetectLowPowerMode && isSystemLowPowerModeActive)
        }

        public init(
            trackpadSensitivity: Double = 1.0,
            scrollSensitivity: Double = 1.0,
            laserSensitivity: Double = 1.0,
            isNaturalScrolling: Bool = true,
            isTapToClick: Bool = true,
            hapticIntensity: HapticIntensity = .medium,
            accentColor: AccentColor = .blue,
            isBatteryOptimizationEnabled: Bool = false,
            autoDetectLowPowerMode: Bool = true,
            reducedMotionUpdateRate: Bool = true,
            reducedAnimations: Bool = true,
            iCloudSyncEnabled: Bool = false
        ) {
            self.trackpadSensitivity = trackpadSensitivity
            self.scrollSensitivity = scrollSensitivity
            self.laserSensitivity = laserSensitivity
            self.isNaturalScrolling = isNaturalScrolling
            self.isTapToClick = isTapToClick
            self.hapticIntensity = hapticIntensity
            self.accentColor = accentColor
            self.isBatteryOptimizationEnabled = isBatteryOptimizationEnabled
            self.autoDetectLowPowerMode = autoDetectLowPowerMode
            self.reducedMotionUpdateRate = reducedMotionUpdateRate
            self.reducedAnimations = reducedAnimations
            self.iCloudSyncEnabled = iCloudSyncEnabled
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

        // Battery Optimization
        case toggleBatteryOptimization
        case toggleAutoDetectLowPowerMode
        case toggleReducedMotionUpdateRate
        case toggleReducedAnimations
        case systemLowPowerModeChanged(Bool)

        // iCloud Sync
        case toggleiCloudSync
        case iCloudSettingsChanged
        case syncToiCloud

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
                state.isiCloudAvailable = settingsClient.isiCloudAvailable()
                return .none

            case .save:
                let currentState = state
                let client = settingsClient
                let shouldSyncToiCloud = state.iCloudSyncEnabled
                let codableSettings = CodableSettings(from: currentState)
                return .run { _ in
                    client.save(currentState)
                    if shouldSyncToiCloud {
                        client.saveToiCloud(codableSettings)
                    }
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

            // Battery Optimization
            case .toggleBatteryOptimization:
                state.isBatteryOptimizationEnabled.toggle()
                return .send(.save)

            case .toggleAutoDetectLowPowerMode:
                state.autoDetectLowPowerMode.toggle()
                return .send(.save)

            case .toggleReducedMotionUpdateRate:
                state.reducedMotionUpdateRate.toggle()
                return .send(.save)

            case .toggleReducedAnimations:
                state.reducedAnimations.toggle()
                return .send(.save)

            case .systemLowPowerModeChanged(let isLowPower):
                state.isSystemLowPowerModeActive = isLowPower
                return .none

            // iCloud Sync
            case .toggleiCloudSync:
                state.iCloudSyncEnabled.toggle()
                let shouldSync = state.iCloudSyncEnabled
                let currentState = state
                let codableSettings = CodableSettings(from: currentState)
                let client = settingsClient
                return .run { _ in
                    client.save(currentState)
                    if shouldSync {
                        // 활성화 시 현재 설정을 iCloud에 저장
                        client.saveToiCloud(codableSettings)
                    }
                }

            case .iCloudSettingsChanged:
                // iCloud에서 설정 변경 알림 받음
                let client = settingsClient
                guard let iCloudSettings = client.loadFromiCloud() else {
                    return .none
                }
                // iCloud 설정을 로컬에 병합 (iCloud가 우선)
                state.trackpadSensitivity = iCloudSettings.trackpadSensitivity
                state.scrollSensitivity = iCloudSettings.scrollSensitivity
                state.laserSensitivity = iCloudSettings.laserSensitivity
                state.isNaturalScrolling = iCloudSettings.isNaturalScrolling
                state.isTapToClick = iCloudSettings.isTapToClick
                state.hapticIntensity = iCloudSettings.hapticIntensity
                state.accentColor = iCloudSettings.accentColor
                state.isBatteryOptimizationEnabled = iCloudSettings.isBatteryOptimizationEnabled
                state.autoDetectLowPowerMode = iCloudSettings.autoDetectLowPowerMode
                state.reducedMotionUpdateRate = iCloudSettings.reducedMotionUpdateRate
                state.reducedAnimations = iCloudSettings.reducedAnimations
                // 로컬에도 저장
                let updatedState = state
                return .run { _ in
                    client.save(updatedState)
                }

            case .syncToiCloud:
                let codableSettings = CodableSettings(from: state)
                let client = settingsClient
                return .run { _ in
                    client.saveToiCloud(codableSettings)
                }

            case .resetToDefaults:
                let wasICloudEnabled = state.iCloudSyncEnabled
                state = State()
                state.iCloudSyncEnabled = wasICloudEnabled
                state.isiCloudAvailable = settingsClient.isiCloudAvailable()
                return .send(.save)
            }
        }
    }
}
