import ComposableArchitecture
import SwiftUI

public struct KeyboardView: View {
    @Bindable var store: StoreOf<KeyboardFeature>
    @FocusState private var isTextFieldFocused: Bool
    @Environment(\.layoutMode) private var layoutMode

    public init(store: StoreOf<KeyboardFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            iPadOptimizedContainer {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mac에 입력").font(.headline)
                        textInputArea
                        Text("입력하는 즉시 Mac으로 전송됩니다. Mac에서 입력할 곳을 먼저 선택하세요.")
                            .font(.caption)
                            .foregroundStyle(SnapColors.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text("조합 키").font(.headline)
                            Spacer()
                            Button("모두 해제") { store.send(.clearModifiers) }
                                .font(.subheadline)
                                .disabled(store.activeModifiers.isEmpty)
                                .frame(minHeight: 44)
                        }
                        modifierKeys
                        Text("한 번 탭하여 선택 · 두 번 탭하여 잠금")
                            .font(.caption)
                            .foregroundStyle(SnapColors.textSecondary)
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("특수 키").font(.headline)
                        specialKeys
                    }
                    VStack(alignment: .leading, spacing: 12) {
                        Text("방향 키").font(.headline)
                        arrowKeys.frame(maxWidth: .infinity)
                    }
                }
                .padding(SnapSpacing.lg)
            }
        }
        .scrollDismissesKeyboard(.interactively)
        .background(SnapColors.systemBackground)
        .toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("키보드 닫기") { isTextFieldFocused = false }
            }
        }
    }

    // MARK: - Text Input Area

    private var textInputArea: some View {
        HStack(spacing: 16) {
            TextField(String(localized: "keyboard.placeholder"), text: $store.inputText.sending(\.textChanged))
                .textFieldStyle(.plain)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .onSubmit { store.send(.returnPressed) }
                .font(.body)
                .padding()
                .background(SnapColors.secondarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(SnapColors.separator, lineWidth: 1)
                )
                .foregroundStyle(SnapColors.label)
                .focused($isTextFieldFocused)
                .accessibilityLabel(String(localized: "keyboard.textInput"))
                .accessibilityHint(String(localized: "keyboard.textInputHint"))

            Button {
                store.send(.clearText)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.title2)
                    .foregroundStyle(SnapColors.tertiaryLabel)
            }
            .frame(minWidth: 44, minHeight: 44)
            .disabled(store.inputText.isEmpty)
            .accessibilityLabel("입력 표시 지우기")
            .accessibilityHint("Mac에 이미 입력한 내용은 지워지지 않습니다")
        }
    }

    // MARK: - Modifier Keys

    private var modifierKeys: some View {
        HStack(spacing: layoutMode == .compact ? 6 : 8) {
            ModifierKeyButton(
                symbol: "⇧",
                label: "Shift",
                isActive: store.activeModifiers.contains(.shift),
                isLocked: store.isShiftLocked
            ) {
                store.send(.shiftTapped)
            } onDoubleTap: {
                store.send(.shiftDoubleTapped)
            }

            ModifierKeyButton(
                symbol: "⌃",
                label: "Ctrl",
                isActive: store.activeModifiers.contains(.control),
                isLocked: store.isControlLocked
            ) {
                store.send(.controlTapped)
            } onDoubleTap: {
                store.send(.controlDoubleTapped)
            }

            ModifierKeyButton(
                symbol: "⌥",
                label: "Opt",
                isActive: store.activeModifiers.contains(.option),
                isLocked: store.isOptionLocked
            ) {
                store.send(.optionTapped)
            } onDoubleTap: {
                store.send(.optionDoubleTapped)
            }

            ModifierKeyButton(
                symbol: "⌘",
                label: "Cmd",
                isActive: store.activeModifiers.contains(.command),
                isLocked: store.isCommandLocked
            ) {
                store.send(.commandTapped)
            } onDoubleTap: {
                store.send(.commandDoubleTapped)
            }
        }
    }

    // MARK: - Special Keys

    private var specialKeys: some View {
        VStack(spacing: layoutMode == .compact ? 6 : 8) {
            HStack(spacing: layoutMode == .compact ? 6 : 8) {
                SpecialKeyButton(label: "Esc", icon: "escape") {
                    store.send(.escapePressed)
                }

                SpecialKeyButton(label: "Tab", icon: "arrow.right.to.line") {
                    store.send(.tabPressed)
                }

                SpecialKeyButton(label: "Delete", icon: "delete.left") {
                    store.send(.deletePressed)
                }

                SpecialKeyButton(label: "Return", icon: "return") {
                    store.send(.returnPressed)
                }
            }

            // Space Bar
            Button {
                store.send(.spacePressed)
            } label: {
                Text("Space")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(SnapColors.label)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(SnapColors.secondarySystemBackground)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(SnapColors.separator, lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
            .accessibilityLabel(String(localized: "keyboard.spaceKey"))
        }
    }

    // MARK: - Arrow Keys

    private var arrowKeys: some View {
        VStack(spacing: layoutMode == .compact ? 6 : 8) {
            ArrowKeyButton(direction: .up) {
                store.send(.arrowPressed(.up))
            }

            HStack(spacing: layoutMode == .compact ? 6 : 8) {
                ArrowKeyButton(direction: .left) {
                    store.send(.arrowPressed(.left))
                }

                ArrowKeyButton(direction: .down) {
                    store.send(.arrowPressed(.down))
                }

                ArrowKeyButton(direction: .right) {
                    store.send(.arrowPressed(.right))
                }
            }
        }
    }
}

// MARK: - Modifier Key Button

struct ModifierKeyButton: View {
    let symbol: String
    let label: String
    let isActive: Bool
    let isLocked: Bool
    let onTap: () -> Void
    let onDoubleTap: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 4) {
            Text(symbol)
                .font(.title3.weight(.medium))

            Text(label)
                .font(.caption2.weight(.medium))
        }
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity)
        .frame(minHeight: 60)
        .background(backgroundColor)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(borderColor, lineWidth: isLocked ? 2 : 1)
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    isPressed = false
                }
        )
        .simultaneousGesture(
            TapGesture()
                .onEnded {
                    onTap()
                }
        )
        .simultaneousGesture(
            TapGesture(count: 2)
                .onEnded {
                    onDoubleTap()
                }
        )
        .accessibilityLabel(String(localized: "keyboard.key \(label)"))
        .accessibilityValue(isLocked ? String(localized: "keyboard.locked") : (isActive ? String(localized: "keyboard.active") : String(localized: "keyboard.inactive")))
        .accessibilityHint(String(localized: "keyboard.toggleHint"))
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { onTap() }
        .accessibilityAction(named: "잠금") { onDoubleTap() }
    }

    private var foregroundColor: Color {
        isActive ? SnapColors.label : SnapColors.secondaryLabel
    }

    private var backgroundColor: Color {
        if isLocked {
            return Color.accentColor.opacity(0.2)
        } else if isActive {
            return SnapColors.tertiarySystemBackground
        }
        return SnapColors.secondarySystemBackground
    }

    private var borderColor: Color {
        if isLocked {
            return .accentColor
        } else if isActive {
            return SnapColors.separator
        }
        return SnapColors.separator.opacity(0.5)
    }
}

// MARK: - Special Key Button

struct SpecialKeyButton: View {
    let label: String
    let icon: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.callout.weight(.medium))

                Text(label)
                    .font(.caption2.weight(.medium))
            }
            .foregroundStyle(SnapColors.label)
            .frame(maxWidth: .infinity)
            .frame(minHeight: 56)
            .background(isPressed ? SnapColors.tertiarySystemFill : SnapColors.secondarySystemBackground)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(SnapColors.separator, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(String(localized: "keyboard.key \(label)"))
        .pressEvents {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Arrow Key Button

struct ArrowKeyButton: View {
    let direction: KeyboardFeature.ArrowDirection
    let action: () -> Void

    @State private var isPressed = false

    private var iconName: String {
        switch direction {
        case .up: return "chevron.up"
        case .down: return "chevron.down"
        case .left: return "chevron.left"
        case .right: return "chevron.right"
        }
    }

    private var accessibilityLabel: String {
        switch direction {
        case .up: return String(localized: "arrow.up")
        case .down: return String(localized: "arrow.down")
        case .left: return String(localized: "arrow.left")
        case .right: return String(localized: "arrow.right")
        }
    }

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.title3.weight(.semibold))
                .foregroundStyle(SnapColors.label)
                .frame(width: 56, height: 44)
                .background(isPressed ? SnapColors.tertiarySystemFill : SnapColors.secondarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(SnapColors.separator, lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .pressEvents {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

#Preview {
    KeyboardView(
        store: Store(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }
    )
}
