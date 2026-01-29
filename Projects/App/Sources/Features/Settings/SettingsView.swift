import ComposableArchitecture
import SwiftUI

public struct SettingsView: View {
    @Bindable var store: StoreOf<SettingsFeature>
    let onDismiss: () -> Void

    public init(store: StoreOf<SettingsFeature>, onDismiss: @escaping () -> Void) {
        self.store = store
        self.onDismiss = onDismiss
    }

    public var body: some View {
        NavigationStack {
            Form {
                // Sensitivity Section
                sensitivitySection

                // Trackpad Options Section
                trackpadOptionsSection

                // Haptic Section
                hapticSection

                // Battery Optimization Section
                batteryOptimizationSection

                // iCloud Sync Section
                iCloudSyncSection

                // Appearance Section
                appearanceSection

                // Reset Section
                resetSection
            }
            .navigationTitle(Text("settings"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        onDismiss()
                    } label: {
                        Text("done")
                    }
                }
            }
            .onAppear {
                store.send(.onAppear)
            }
        }
    }

    // MARK: - Sensitivity Section

    @ViewBuilder
    private var sensitivitySection: some View {
        Section {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("settings.trackpadSensitivity")
                    Spacer()
                    Text(String(format: "%.1f", store.trackpadSensitivity))
                        .foregroundStyle(SnapColors.textSecondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.trackpadSensitivity.sending(\.setTrackpadSensitivity),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "settings.trackpadSensitivity"))
            .accessibilityValue(String(format: "%.1f", store.trackpadSensitivity))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("settings.scrollSensitivity")
                    Spacer()
                    Text(String(format: "%.1f", store.scrollSensitivity))
                        .foregroundStyle(SnapColors.textSecondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.scrollSensitivity.sending(\.setScrollSensitivity),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "settings.scrollSensitivity"))
            .accessibilityValue(String(format: "%.1f", store.scrollSensitivity))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("settings.laserSensitivity")
                    Spacer()
                    Text(String(format: "%.1f", store.laserSensitivity))
                        .foregroundStyle(SnapColors.textSecondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.laserSensitivity.sending(\.setLaserSensitivity),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel(String(localized: "settings.laserSensitivity"))
            .accessibilityValue(String(format: "%.1f", store.laserSensitivity))
        } header: {
            Text("settings.sensitivity")
        }
    }

    // MARK: - Trackpad Options Section

    @ViewBuilder
    private var trackpadOptionsSection: some View {
        Section {
            Toggle(String(localized: "settings.naturalScrolling"), isOn: Binding(
                get: { store.isNaturalScrolling },
                set: { _ in store.send(.toggleNaturalScrolling) }
            ))

            Toggle(String(localized: "settings.tapToClick"), isOn: Binding(
                get: { store.isTapToClick },
                set: { _ in store.send(.toggleTapToClick) }
            ))
        } header: {
            Text("settings.trackpad")
        }
    }

    // MARK: - Haptic Section

    @ViewBuilder
    private var hapticSection: some View {
        Section {
            Picker(String(localized: "settings.hapticIntensity"), selection: Binding(
                get: { store.hapticIntensity },
                set: { store.send(.setHapticIntensity($0)) }
            )) {
                ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.title).tag(intensity)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("settings.hapticFeedback")
        } footer: {
            Text("settings.hapticFooter")
        }
    }

    // MARK: - Battery Optimization Section

    @ViewBuilder
    private var batteryOptimizationSection: some View {
        Section {
            Toggle(String(localized: "settings.batteryOptimization"), isOn: Binding(
                get: { store.isBatteryOptimizationEnabled },
                set: { _ in store.send(.toggleBatteryOptimization) }
            ))

            Toggle(String(localized: "settings.autoDetectLowPowerMode"), isOn: Binding(
                get: { store.autoDetectLowPowerMode },
                set: { _ in store.send(.toggleAutoDetectLowPowerMode) }
            ))

            if store.isBatteryOptimizationEnabled || store.autoDetectLowPowerMode {
                Toggle(String(localized: "settings.reducedMotionUpdateRate"), isOn: Binding(
                    get: { store.reducedMotionUpdateRate },
                    set: { _ in store.send(.toggleReducedMotionUpdateRate) }
                ))

                Toggle(String(localized: "settings.reducedAnimations"), isOn: Binding(
                    get: { store.reducedAnimations },
                    set: { _ in store.send(.toggleReducedAnimations) }
                ))
            }

            if store.isSystemLowPowerModeActive {
                HStack {
                    Image(systemName: "battery.25")
                        .foregroundStyle(.orange)
                    Text("settings.lowPowerModeActive")
                        .foregroundStyle(SnapColors.textSecondary)
                }
            }
        } header: {
            Text("settings.batteryOptimizationHeader")
        } footer: {
            Text("settings.batteryOptimizationFooter")
        }
    }

    // MARK: - iCloud Sync Section

    @ViewBuilder
    private var iCloudSyncSection: some View {
        Section {
            if store.isiCloudAvailable {
                Toggle(String(localized: "settings.iCloudSync"), isOn: Binding(
                    get: { store.iCloudSyncEnabled },
                    set: { _ in store.send(.toggleiCloudSync) }
                ))
            } else {
                HStack {
                    Image(systemName: "exclamationmark.icloud")
                        .foregroundStyle(.secondary)
                    Text("settings.iCloudUnavailable")
                        .foregroundStyle(SnapColors.textSecondary)
                }
            }
        } header: {
            Text("settings.iCloudSyncHeader")
        } footer: {
            Text("settings.iCloudSyncFooter")
        }
    }

    // MARK: - Appearance Section

    @ViewBuilder
    private var appearanceSection: some View {
        Section {
            LazyVGrid(columns: [
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible()),
                GridItem(.flexible())
            ], spacing: 12) {
                ForEach(AccentColor.allCases, id: \.self) { color in
                    ColorButton(
                        color: color,
                        isSelected: store.accentColor == color
                    ) {
                        store.send(.setAccentColor(color))
                    }
                }
            }
            .padding(.vertical, 8)
        } header: {
            Text("settings.themeColor")
        }
    }

    // MARK: - Reset Section

    @ViewBuilder
    private var resetSection: some View {
        Section {
            Button(role: .destructive) {
                store.send(.resetToDefaults)
            } label: {
                HStack {
                    Spacer()
                    Text("settings.resetToDefaults")
                    Spacer()
                }
            }
        }
    }
}

// MARK: - Color Button

private struct ColorButton: View {
    let color: AccentColor
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .fill(color.color)
                    .frame(width: 44, height: 44)

                if isSelected {
                    Circle()
                        .strokeBorder(.white, lineWidth: 2)
                        .frame(width: 44, height: 44)

                    Image(systemName: "checkmark")
                        .font(.callout.weight(.bold))
                        .foregroundStyle(.white)
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(color.title)
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
    }
}

#Preview {
    SettingsView(
        store: Store(initialState: SettingsFeature.State()) {
            SettingsFeature()
        },
        onDismiss: {}
    )
}
