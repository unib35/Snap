import ComposableArchitecture
import SwiftUI

public struct KeyboardView: View {
    @Bindable var store: StoreOf<KeyboardFeature>
    @FocusState private var isTextFieldFocused: Bool

    public init(store: StoreOf<KeyboardFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Text Input Area
            textInputArea
                .padding()

            // Modifier Keys
            modifierKeys
                .padding(.horizontal)

            Spacer()

            // Special Keys
            specialKeys
                .padding()

            // Arrow Keys
            arrowKeys
                .padding()
        }
        .background(Color.black)
    }

    // MARK: - Text Input Area

    private var textInputArea: some View {
        HStack(spacing: 12) {
            TextField("Type here...", text: $store.inputText.sending(\.textChanged))
                .textFieldStyle(.plain)
                .font(.system(size: 18))
                .padding()
                .background(Color.white.opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.white.opacity(0.2), lineWidth: 1)
                )
                .foregroundStyle(.white)
                .focused($isTextFieldFocused)

            Button {
                store.send(.clearText)
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(Color.white.opacity(0.5))
            }
            .opacity(store.inputText.isEmpty ? 0 : 1)
        }
    }

    // MARK: - Modifier Keys

    private var modifierKeys: some View {
        HStack(spacing: 8) {
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
        VStack(spacing: 8) {
            HStack(spacing: 8) {
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
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Arrow Keys

    private var arrowKeys: some View {
        VStack(spacing: 4) {
            ArrowKeyButton(direction: .up) {
                store.send(.arrowPressed(.up))
            }

            HStack(spacing: 4) {
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
                .font(.system(size: 20, weight: .medium))

            Text(label)
                .font(.system(size: 10, weight: .medium))
        }
        .foregroundStyle(foregroundColor)
        .frame(maxWidth: .infinity)
        .frame(height: 60)
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
    }

    private var foregroundColor: Color {
        isActive ? .white : .gray
    }

    private var backgroundColor: Color {
        if isLocked {
            return Color.blue.opacity(0.3)
        } else if isActive {
            return Color.white.opacity(0.15)
        }
        return Color.white.opacity(0.05)
    }

    private var borderColor: Color {
        if isLocked {
            return .blue
        } else if isActive {
            return Color.white.opacity(0.2)
        }
        return Color.white.opacity(0.1)
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
                    .font(.system(size: 16, weight: .medium))

                Text(label)
                    .font(.system(size: 10, weight: .medium))
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(Color.white.opacity(isPressed ? 0.15 : 0.08))
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: iconName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 56, height: 44)
                .background(Color.white.opacity(isPressed ? 0.15 : 0.08))
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
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
    .preferredColorScheme(.dark)
}
