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

                // Appearance Section
                appearanceSection

                // Reset Section
                resetSection
            }
            .navigationTitle("설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("완료") {
                        onDismiss()
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
                    Text("트랙패드 감도")
                    Spacer()
                    Text(String(format: "%.1f", store.trackpadSensitivity))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.trackpadSensitivity.sending(\.setTrackpadSensitivity),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("트랙패드 감도")
            .accessibilityValue(String(format: "%.1f", store.trackpadSensitivity))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("스크롤 감도")
                    Spacer()
                    Text(String(format: "%.1f", store.scrollSensitivity))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.scrollSensitivity.sending(\.setScrollSensitivity),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("스크롤 감도")
            .accessibilityValue(String(format: "%.1f", store.scrollSensitivity))

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("레이저 포인터 감도")
                    Spacer()
                    Text(String(format: "%.1f", store.laserSensitivity))
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
                Slider(
                    value: $store.laserSensitivity.sending(\.setLaserSensitivity),
                    in: 0.5...2.0,
                    step: 0.1
                )
            }
            .accessibilityElement(children: .combine)
            .accessibilityLabel("레이저 포인터 감도")
            .accessibilityValue(String(format: "%.1f", store.laserSensitivity))
        } header: {
            Text("감도")
        }
    }

    // MARK: - Trackpad Options Section

    @ViewBuilder
    private var trackpadOptionsSection: some View {
        Section {
            Toggle("자연스러운 스크롤", isOn: Binding(
                get: { store.isNaturalScrolling },
                set: { _ in store.send(.toggleNaturalScrolling) }
            ))

            Toggle("탭하여 클릭", isOn: Binding(
                get: { store.isTapToClick },
                set: { _ in store.send(.toggleTapToClick) }
            ))
        } header: {
            Text("트랙패드")
        }
    }

    // MARK: - Haptic Section

    @ViewBuilder
    private var hapticSection: some View {
        Section {
            Picker("햅틱 강도", selection: Binding(
                get: { store.hapticIntensity },
                set: { store.send(.setHapticIntensity($0)) }
            )) {
                ForEach(HapticIntensity.allCases, id: \.self) { intensity in
                    Text(intensity.title).tag(intensity)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("햅틱 피드백")
        } footer: {
            Text("터치 시 진동 피드백의 강도를 설정합니다.")
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
            Text("테마 색상")
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
                    Text("기본값으로 재설정")
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
                        .font(.system(size: 16, weight: .bold))
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
