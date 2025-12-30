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
        .background(
            LinearGradient(
                colors: [Color(white: 0.08), Color.black],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        let toggleShape = RoundedRectangle(cornerRadius: 14)

        return HStack(spacing: 4) {
            ForEach(TrackpadFeature.InputMode.allCases, id: \.self) { mode in
                ModeToggleButton(
                    mode: mode,
                    isSelected: store.mode == mode
                ) {
                    store.send(.modeChanged(mode), animation: .spring(response: 0.3, dampingFraction: 0.7))
                }
            }
        }
        .padding(4)
        .background(Color(white: 0.12))
        .clipShape(toggleShape)
        .overlay(
            toggleShape.strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
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
            HStack(spacing: 12) {
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
            HStack(spacing: 12) {
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
                    color: .gray
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
        HStack(spacing: 12) {
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
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(mode.title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .shadow(color: shadowColor, radius: isSelected ? 8 : 0)
        }
        .buttonStyle(.plain)
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
        return isSelected ? .white : .gray
    }

    private var textColor: Color {
        isSelected ? .white : .gray
    }

    private var background: AnyShapeStyle {
        if isSelected {
            if mode == .laser {
                return AnyShapeStyle(Color.red.opacity(0.15))
            }
            return AnyShapeStyle(Color(white: 0.18))
        }
        return AnyShapeStyle(Color.clear)
    }

    private var borderColor: Color {
        if isSelected {
            if mode == .laser {
                return .red.opacity(0.3)
            }
            return .white.opacity(0.1)
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
                    .fill(Color(white: 0.06))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                    )

                // Ping Animation (always animating in center)
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pingAnimation ? 1.5 : 1.0)
                    .opacity(pingAnimation ? 0 : 0.3)
                    .animation(
                        .easeOut(duration: 2.0).repeatForever(autoreverses: false),
                        value: pingAnimation
                    )

                // Watermark
                Text("TRACKPAD")
                    .font(.system(size: 32, weight: .black))
                    .foregroundStyle(Color.white.opacity(0.04))
                    .tracking(10)

                // Touch indicator - follows finger
                if store.isTouching {
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.white.opacity(0.25), Color.white.opacity(0)],
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
        .onAppear {
            pingAnimation = true
        }
    }
}

// MARK: - Laser Control Area

struct LaserControlArea: View {
    let store: StoreOf<TrackpadFeature>
    @State private var isHolding = false

    private var laserButtonFill: AnyShapeStyle {
        if isHolding {
            return AnyShapeStyle(Color.red)
        } else {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(white: 0.15), Color(white: 0.08)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
    }

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(Color(white: 0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
                )

            VStack(spacing: 8) {
                Text("GYRO CONTROL")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gray)
                    .tracking(2)

                Spacer()

                // Laser Button
                ZStack {
                    // Outer glow (pulsing when active)
                    if isHolding {
                        Circle()
                            .fill(Color.red.opacity(0.2))
                            .frame(width: 220, height: 220)
                            .blur(radius: 40)
                            .modifier(PulseModifier())
                    }

                    // Button shadow glow
                    Circle()
                        .fill(Color.red.opacity(isHolding ? 0.5 : 0))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    // Main button
                    Circle()
                        .fill(laserButtonFill)
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isHolding ? Color.red.opacity(0.6) : Color.white.opacity(0.1),
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isHolding ? 0.95 : 1.0)

                    VStack(spacing: 8) {
                        Image(systemName: "scope")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(isHolding ? .white : .red)

                        Text(isHolding ? "GYRO ACTIVE" : "HOLD TO MOVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundStyle(isHolding ? .white : .gray)
                            .tracking(1)
                    }
                }
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isHolding)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isHolding {
                                isHolding = true
                            }
                        }
                        .onEnded { _ in
                            isHolding = false
                        }
                )

                Spacer()
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
            .font(.system(size: 16, weight: .bold))
            .foregroundStyle(isPrimary ? .white : Color.white.opacity(0.5))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isPressed ? Color.white.opacity(0.15) : Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(Color.white.opacity(0.08), lineWidth: 1)
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
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 24, weight: .medium))
                .foregroundStyle(isPressed ? .white : color)

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(Color.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? Color.white.opacity(0.15) : Color(white: 0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
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
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color.white.opacity(0.7))

                Text(label)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(Color.gray)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(Color(white: 0.1))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(Color.white.opacity(0.05), lineWidth: 1)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
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
    .preferredColorScheme(.dark)
}
