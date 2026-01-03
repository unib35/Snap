import ComposableArchitecture
import SwiftUI

public struct TrackpadView: View {
    @Bindable var store: StoreOf<TrackpadFeature>

    public init(store: StoreOf<TrackpadFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Mode Toggle
            modeToggle
                .padding()

            // Main Content
            Group {
                if store.mode == .trackpad {
                    trackpadContent
                } else {
                    laserContent
                }
            }
            .animation(.easeInOut(duration: 0.3), value: store.mode)

            // Quick Actions
            quickActions
                .padding()
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        let toggleShape = RoundedRectangle(cornerRadius: 12)

        return HStack(spacing: 8) {
            ForEach(TrackpadFeature.InputMode.allCases, id: \.self) { mode in
                ModeToggleButton(
                    mode: mode,
                    isSelected: store.mode == mode
                ) {
                    store.send(.modeChanged(mode), animation: .spring(response: 0.3, dampingFraction: 0.7))
                }
            }
        }
        .padding(8)
        .background(Color(.secondarySystemBackground))
        .clipShape(toggleShape)
        .overlay(
            toggleShape.strokeBorder(Color(.separator), lineWidth: 1)
        )
    }

    // MARK: - Trackpad Content

    @ViewBuilder
    private var trackpadContent: some View {
        VStack(spacing: 0) {
            // Touch Area
            TrackpadTouchArea(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Click Buttons - Inside the touch area at bottom
            HStack(spacing: 16) {
                ClickButton(label: "L", isPrimary: true) {
                    store.send(.leftClickPressed)
                } onRelease: {
                    store.send(.leftClickReleased)
                }

                ClickButton(label: "R", isPrimary: false) {
                    store.send(.rightClickPressed)
                } onRelease: {
                    store.send(.rightClickReleased)
                }
            }
            .frame(height: 64)
            .padding(.horizontal)
            .padding(.top, 16)
            .padding(.bottom, 8)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - Laser Content

    @ViewBuilder
    private var laserContent: some View {
        VStack(spacing: 16) {
            // Gyro Control Area
            LaserControlArea(store: store)
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Click Buttons
            HStack(spacing: 16) {
                LaserClickButton(
                    icon: "cursorarrow.click",
                    label: "Left Click",
                    color: .blue
                ) {
                    store.send(.leftClickPressed)
                } onRelease: {
                    store.send(.leftClickReleased)
                }

                LaserClickButton(
                    icon: "cursorarrow.click",
                    label: "Right Click",
                    color: .secondary
                ) {
                    store.send(.rightClickPressed)
                } onRelease: {
                    store.send(.rightClickReleased)
                }
            }
            .frame(height: 80)
            .padding(.horizontal)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActions: some View {
        HStack(spacing: 16) {
            QuickActionButton(
                icon: "command",
                label: "Cmd+Space"
            ) {
                store.send(.spotlightPressed)
            }

            QuickActionButton(
                icon: "square.grid.2x2",
                label: "Mission Ctrl"
            ) {
                store.send(.missionControlPressed)
            }
        }
    }
}

// MARK: - Mode Toggle Button

struct ModeToggleButton: View {
    let mode: TrackpadFeature.InputMode
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: mode == .trackpad ? "hand.point.up.left" : "scope")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(iconColor)

                Text(mode.title)
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: shadowColor, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(mode.title) 모드")
        .accessibilityAddTraits(isSelected ? [.isSelected] : [])
        .pressEvents {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = false
            }
        }
    }

    private var iconColor: Color {
        if mode == .laser && isSelected {
            return .red
        }
        return isSelected ? Color(.label) : Color(.tertiaryLabel)
    }

    private var textColor: Color {
        isSelected ? Color(.label) : Color(.tertiaryLabel)
    }

    private var background: Color {
        if isSelected {
            if mode == .laser {
                return Color.red.opacity(0.15)
            }
            return Color(.tertiarySystemBackground)
        }
        return Color.clear
    }

    private var borderColor: Color {
        if isSelected {
            if mode == .laser {
                return .red.opacity(0.3)
            }
            return Color(.separator)
        }
        return .clear
    }

    private var shadowColor: Color {
        if mode == .laser && isSelected {
            return .red.opacity(0.3)
        }
        return .clear
    }
}

// MARK: - Trackpad Touch Area

struct TrackpadTouchArea: View {
    let store: StoreOf<TrackpadFeature>
    @State private var pingAnimation = false

    var body: some View {
        GeometryReader { _ in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )

                // Ping Animation (always animating in center)
                Circle()
                    .stroke(Color(.tertiaryLabel), lineWidth: 1)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pingAnimation ? 1.5 : 1.0)
                    .opacity(pingAnimation ? 0 : 0.3)
                    .animation(
                        .easeOut(duration: 2.0).repeatForever(autoreverses: false),
                        value: pingAnimation
                    )

                // Watermark
                Text("TRACKPAD")
                    .font(.largeTitle.weight(.black))
                    .foregroundStyle(Color(.quaternaryLabel))
                    .tracking(10)

                // Touch indicator - follows finger
                if store.isTouching {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0)],
                                center: .center,
                                startRadius: 0,
                                endRadius: 60
                            )
                        )
                        .frame(width: 120, height: 120)
                        .position(store.lastTouchPosition)
                        .animation(.interactiveSpring(response: 0.1), value: store.lastTouchPosition)
                }
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !store.isTouching {
                            store.send(.touchBegan(value.location))
                        } else {
                            store.send(.touchMoved(value.location))
                        }
                    }
                    .onEnded { _ in
                        store.send(.touchEnded)
                    }
            )
            .simultaneousGesture(
                TapGesture()
                    .onEnded {
                        store.send(.tapped)
                    }
            )
            .simultaneousGesture(
                TapGesture(count: 2)
                    .onEnded {
                        store.send(.doubleTapped)
                    }
            )
        }
        .padding(.horizontal)
        .accessibilityLabel("트랙패드 터치 영역")
        .accessibilityHint("드래그하여 마우스를 이동하고, 탭하여 클릭합니다")
        .onAppear {
            pingAnimation = true
        }
    }
}

// MARK: - Laser Control Area

struct LaserControlArea: View {
    let store: StoreOf<TrackpadFeature>

    var body: some View {
        let isActive = store.laserPointer.isActive

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )

            VStack(spacing: 8) {
                Text("GYRO CONTROL")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Color(.secondaryLabel))
                    .tracking(2)

                Spacer()

                // Laser Button (Press and Hold)
                ZStack {
                    // Outer glow (pulsing when active)
                    if isActive {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 220, height: 220)
                            .blur(radius: 40)
                            .modifier(PulseModifier())
                    }

                    // Button shadow glow
                    Circle()
                        .fill(Color.red.opacity(isActive ? 0.5 : 0))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    // Main button
                    Circle()
                        .fill(isActive ? Color.red : Color(.tertiarySystemBackground))
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isActive ? Color.red.opacity(0.6) : Color(.separator),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isActive ? 0.95 : 1.0)

                    VStack(spacing: 8) {
                        Image(systemName: "scope")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(isActive ? .white : .red)
                            .symbolEffect(.pulse, isActive: isActive)

                        Text(isActive ? "GYRO ACTIVE" : "HOLD TO MOVE")
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isActive ? .white : Color(.secondaryLabel))
                            .tracking(1)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isActive)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isActive {
                                store.send(.laserPointer(.startPointing))
                            }
                        }
                        .onEnded { _ in
                            store.send(.laserPointer(.stopPointing))
                        }
                )
                .accessibilityLabel("레이저 포인터 버튼")
                .accessibilityHint("길게 누르고 있으면 자이로스코프 마우스 제어가 활성화됩니다")

                Spacer()

                // Sensitivity & Calibrate
                if isActive {
                    VStack(spacing: 12) {
                        // Sensitivity slider
                        HStack {
                            Image(systemName: "tortoise")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            Slider(
                                value: Binding(
                                    get: { Double(store.laserPointer.sensitivity) },
                                    set: { store.send(.laserPointer(.setSensitivity(Float($0)))) }
                                ),
                                in: 1...50
                            )
                            .tint(.red)

                            Image(systemName: "hare")
                                .foregroundStyle(.secondary)
                                .font(.caption)
                        }

                        // Calibrate button
                        Button {
                            store.send(.laserPointer(.calibrate))
                        } label: {
                            Label("기준점 재설정", systemImage: "scope")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    .padding(.horizontal)
                    .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
            }
            .padding()
        }
        .padding(.horizontal)
    }
}

// MARK: - Pulse Modifier

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.1 : 1.0)
            .opacity(isPulsing ? 0.7 : 1.0)
            .animation(
                .easeInOut(duration: 0.8).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .onAppear {
                isPulsing = true
            }
    }
}

// MARK: - Click Button

struct ClickButton: View {
    let label: String
    let isPrimary: Bool
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(label)
            .font(.headline)
            .foregroundStyle(isPrimary ? Color(.label) : Color(.secondaryLabel))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPressed ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color(.separator), lineWidth: 1)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            onPress()
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        onRelease()
                    }
            )
            .accessibilityLabel(isPrimary ? "왼쪽 클릭" : "오른쪽 클릭")
    }
}

// MARK: - Laser Click Button

struct LaserClickButton: View {
    let icon: String
    let label: String
    let color: Color
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(isPressed ? Color(.label) : color)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(Color(.secondaryLabel))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color(.tertiarySystemFill) : Color(.secondarySystemBackground))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
        )
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onPress()
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onRelease()
                }
        )
        .accessibilityLabel(label)
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color(.secondaryLabel))

                Text(label)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(Color(.tertiaryLabel))
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color(.separator), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .pressEvents {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.15, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }
}

// MARK: - Press Events Modifier

struct PressEventsModifier: ViewModifier {
    var onPress: () -> Void
    var onRelease: () -> Void

    func body(content: Content) -> some View {
        content
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in onPress() }
                    .onEnded { _ in onRelease() }
            )
    }
}

extension View {
    func pressEvents(onPress: @escaping () -> Void, onRelease: @escaping () -> Void) -> some View {
        modifier(PressEventsModifier(onPress: onPress, onRelease: onRelease))
    }
}

#Preview {
    TrackpadView(
        store: Store(initialState: TrackpadFeature.State()) {
            TrackpadFeature()
        }
    )
}
