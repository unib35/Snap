import ComposableArchitecture
import Shared
import SwiftUI
import UIKit

public struct TrackpadView: View {
    @Bindable var store: StoreOf<TrackpadFeature>

    public init(store: StoreOf<TrackpadFeature>) {
        self.store = store
    }

    @Namespace private var modeNamespace

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
            .animation(.spring(response: 0.4, dampingFraction: 0.8), value: store.mode)

            // Quick Actions
            quickActions
                .padding()
        }
        .background(SnapColors.background)
    }

    // MARK: - Mode Toggle

    private var modeToggle: some View {
        let toggleShape = RoundedRectangle(cornerRadius: SnapCornerRadius.md)

        return HStack(spacing: SnapSpacing.sm) {
            ForEach(TrackpadFeature.InputMode.allCases, id: \.self) { mode in
                ModeToggleButton(
                    mode: mode,
                    isSelected: store.mode == mode,
                    namespace: modeNamespace
                ) {
                    Task { @MainActor in
                        HapticManager.shared.modeSwitch()
                    }
                    store.send(.modeChanged(mode), animation: .spring(response: 0.3, dampingFraction: 0.7))
                }
            }
        }
        .padding(SnapSpacing.sm)
        .background(SnapColors.backgroundElevated)
        .clipShape(toggleShape)
        .overlay(
            toggleShape.strokeBorder(SnapColors.border, lineWidth: 0.5)
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
        VStack(spacing: 12) {
            // Gyro Control Area (constrained height)
            LaserControlArea(store: store)
                .frame(maxHeight: 350)

            // Click Buttons (fixed height, won't shrink)
            HStack(spacing: 12) {
                LaserClickButton(
                    icon: "cursorarrow.click",
                    label: "Left Click",
                    color: .accentColor
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
            .fixedSize(horizontal: false, vertical: true)
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - Quick Actions

    @ViewBuilder
    private var quickActions: some View {
        HStack(spacing: 16) {
            VoiceTypingButton(
                isRecording: store.voiceTyping.isRecording,
                isAuthorized: store.voiceTyping.authorizationStatus == .authorized
            ) {
                store.send(.voiceTyping(.toggleRecording))
            }

            QuickActionButton(
                icon: "square.grid.2x2",
                label: "Mission Ctrl"
            ) {
                store.send(.missionControlPressed)
            }
        }
        .onAppear {
            store.send(.voiceTyping(.onAppear))
        }
    }
}

// MARK: - Voice Typing Button

struct VoiceTypingButton: View {
    let isRecording: Bool
    let isAuthorized: Bool
    let action: () -> Void

    var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            VStack(spacing: SnapSpacing.sm) {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundStyle(isRecording ? SnapColors.recording : Color.accentColor)
                    .symbolEffect(.variableColor.iterative, isActive: isRecording)

                Text(isRecording ? "중지" : "음성입력")
                    .font(SnapTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(SnapColors.textTertiary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.lg)
            .background(isRecording ? SnapColors.recording.opacity(0.15) : SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                    .strokeBorder(isRecording ? SnapColors.recording.opacity(0.5) : Color.clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .pressEffect()
        .disabled(!isAuthorized)
        .opacity(isAuthorized ? 1 : 0.5)
    }
}

// MARK: - Mode Toggle Button

struct ModeToggleButton: View {
    let mode: TrackpadFeature.InputMode
    let isSelected: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: SnapSpacing.sm) {
                Image(systemName: mode == .trackpad ? "hand.point.up.left" : "scope")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(iconColor)

                Text(mode.title)
                    .font(SnapTypography.labelMedium)
                    .fontWeight(.bold)
                    .foregroundStyle(textColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.md)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: SnapCornerRadius.sm)
                        .fill(background)
                        .matchedGeometryEffect(id: "modeSelection", in: namespace)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.sm))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.sm)
                    .strokeBorder(borderColor, lineWidth: isSelected ? 1 : 0)
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
            return SnapColors.laserPointer
        }
        return isSelected ? SnapColors.textPrimary : SnapColors.textTertiary
    }

    private var textColor: Color {
        isSelected ? SnapColors.textPrimary : SnapColors.textTertiary
    }

    private var background: Color {
        if mode == .laser {
            return SnapColors.laserPointer.opacity(0.15)
        }
        return SnapColors.backgroundTertiary
    }

    private var borderColor: Color {
        if isSelected {
            if mode == .laser {
                return SnapColors.laserPointer.opacity(0.3)
            }
            return SnapColors.border
        }
        return .clear
    }

    private var shadowColor: Color {
        if mode == .laser && isSelected {
            return SnapColors.laserPointer.opacity(0.3)
        }
        return .clear
    }
}

// MARK: - Trackpad Touch Area

struct TrackpadTouchArea: View {
    let store: StoreOf<TrackpadFeature>
    @State private var pingAnimation = false

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: SnapCornerRadius.xxl)
                .fill(SnapColors.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SnapCornerRadius.xxl)
                        .strokeBorder(SnapColors.border, lineWidth: 0.5)
                )

            // Ping Animation (always animating in center)
            Circle()
                .stroke(SnapColors.textDisabled, lineWidth: 1)
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
                .foregroundStyle(SnapColors.textDisabled.opacity(0.5))
                .tracking(10)

            // Touch indicator - follows finger
            if store.isTouching {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.4), Color.accentColor.opacity(0)],
                            center: .center,
                            startRadius: 0,
                            endRadius: 60
                        )
                    )
                    .frame(width: 120, height: 120)
                    .position(store.lastTouchPosition)
                    .animation(.interactiveSpring(response: 0.1), value: store.lastTouchPosition)
            }

            // UIKit Gesture Layer
            TrackpadGestureView(
                onTouchBegan: { point in store.send(.touchBegan(point)) },
                onTouchMoved: { point in store.send(.touchMoved(point)) },
                onTouchEnded: { store.send(.touchEnded) },
                onTap: { store.send(.tapped) },
                onDoubleTap: { store.send(.doubleTapped) },
                onTwoFingerTap: { store.send(.twoFingerTapped) },
                onScroll: { dx, dy in store.send(.scrolled(deltaX: dx, deltaY: dy)) },
                onPinch: { scale, phase in store.send(.pinched(scale: scale, phase: phase)) }
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

// MARK: - UIKit Gesture View

struct TrackpadGestureView: UIViewRepresentable {
    let onTouchBegan: (CGPoint) -> Void
    let onTouchMoved: (CGPoint) -> Void
    let onTouchEnded: () -> Void
    let onTap: () -> Void
    let onDoubleTap: () -> Void
    let onTwoFingerTap: () -> Void
    let onScroll: (CGFloat, CGFloat) -> Void
    let onPinch: (CGFloat, Pinch.Phase) -> Void

    func makeUIView(context: Context) -> TrackpadGestureUIView {
        let view = TrackpadGestureUIView()
        view.onTouchBegan = onTouchBegan
        view.onTouchMoved = onTouchMoved
        view.onTouchEnded = onTouchEnded
        view.onTap = onTap
        view.onDoubleTap = onDoubleTap
        view.onTwoFingerTap = onTwoFingerTap
        view.onScroll = onScroll
        view.onPinch = onPinch
        return view
    }

    func updateUIView(_ uiView: TrackpadGestureUIView, context: Context) {
        uiView.onTouchBegan = onTouchBegan
        uiView.onTouchMoved = onTouchMoved
        uiView.onTouchEnded = onTouchEnded
        uiView.onTap = onTap
        uiView.onDoubleTap = onDoubleTap
        uiView.onTwoFingerTap = onTwoFingerTap
        uiView.onScroll = onScroll
        uiView.onPinch = onPinch
    }
}

// MARK: - UIKit Gesture UIView

class TrackpadGestureUIView: UIView {
    var onTouchBegan: ((CGPoint) -> Void)?
    var onTouchMoved: ((CGPoint) -> Void)?
    var onTouchEnded: (() -> Void)?
    var onTap: (() -> Void)?
    var onDoubleTap: (() -> Void)?
    var onTwoFingerTap: (() -> Void)?
    var onScroll: ((CGFloat, CGFloat) -> Void)?
    var onPinch: ((CGFloat, Pinch.Phase) -> Void)?

    private var lastPanLocation: CGPoint = .zero
    private var isSingleFingerDrag = false

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGestures()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGestures()
    }

    private func setupGestures() {
        backgroundColor = .clear
        isMultipleTouchEnabled = true

        // Single tap
        let singleTap = UITapGestureRecognizer(target: self, action: #selector(handleSingleTap))
        singleTap.numberOfTapsRequired = 1
        singleTap.numberOfTouchesRequired = 1
        addGestureRecognizer(singleTap)

        // Double tap
        let doubleTap = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap))
        doubleTap.numberOfTapsRequired = 2
        doubleTap.numberOfTouchesRequired = 1
        addGestureRecognizer(doubleTap)

        // Two finger tap (right click)
        let twoFingerTap = UITapGestureRecognizer(target: self, action: #selector(handleTwoFingerTap))
        twoFingerTap.numberOfTapsRequired = 1
        twoFingerTap.numberOfTouchesRequired = 2
        addGestureRecognizer(twoFingerTap)

        // Single finger pan (mouse move)
        let singlePan = UIPanGestureRecognizer(target: self, action: #selector(handleSinglePan))
        singlePan.minimumNumberOfTouches = 1
        singlePan.maximumNumberOfTouches = 1
        addGestureRecognizer(singlePan)

        // Two finger pan (scroll)
        let twoFingerPan = UIPanGestureRecognizer(target: self, action: #selector(handleTwoFingerPan))
        twoFingerPan.minimumNumberOfTouches = 2
        twoFingerPan.maximumNumberOfTouches = 2
        addGestureRecognizer(twoFingerPan)

        // Pinch (zoom)
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch))
        addGestureRecognizer(pinch)

        // Gesture dependencies
        singleTap.require(toFail: doubleTap)
        singlePan.require(toFail: twoFingerPan)
    }

    @objc private func handleSingleTap(_ gesture: UITapGestureRecognizer) {
        onTap?()
    }

    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        onDoubleTap?()
    }

    @objc private func handleTwoFingerTap(_ gesture: UITapGestureRecognizer) {
        onTwoFingerTap?()
    }

    @objc private func handleSinglePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)

        switch gesture.state {
        case .began:
            isSingleFingerDrag = true
            lastPanLocation = location
            onTouchBegan?(location)
        case .changed:
            if isSingleFingerDrag {
                onTouchMoved?(location)
                lastPanLocation = location
            }
        case .ended, .cancelled:
            isSingleFingerDrag = false
            onTouchEnded?()
        default:
            break
        }
    }

    @objc private func handleTwoFingerPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        gesture.setTranslation(.zero, in: self)

        if gesture.state == .changed {
            onScroll?(translation.x, translation.y)
        }
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        let phase: Pinch.Phase
        switch gesture.state {
        case .began:
            phase = .began
        case .changed:
            phase = .changed
        case .ended, .cancelled:
            phase = .ended
        default:
            return
        }

        onPinch?(gesture.scale, phase)

        // Reset scale for incremental updates
        if gesture.state == .changed {
            gesture.scale = 1.0
        }
    }
}

// MARK: - Laser Control Area

struct LaserControlArea: View {
    @Bindable var store: StoreOf<TrackpadFeature>

    var body: some View {
        let isActive = store.laserPointer.isActive
        let activationMode = store.laserPointer.activationMode

        ZStack {
            // Background
            RoundedRectangle(cornerRadius: 24)
                .fill(SnapColors.secondarySystemBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .strokeBorder(SnapColors.separator, lineWidth: 1)
                )

            VStack(spacing: 12) {
                // Mode Selector
                HStack(spacing: 0) {
                    ForEach(LaserPointerFeature.ActivationMode.allCases, id: \.self) { mode in
                        Button {
                            store.send(.laserPointer(.setActivationMode(mode)))
                        } label: {
                            Text(mode.rawValue)
                                .font(.caption.weight(.bold))
                                .foregroundStyle(activationMode == mode ? .white : .secondary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 6)
                                .background(activationMode == mode ? SnapColors.laserPointer : Color.clear)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(3)
                .background(SnapColors.tertiarySystemBackground)
                .clipShape(Capsule())
                .padding(.horizontal)

                // Laser Button (fixed frame to prevent layout shift)
                ZStack {
                    // Outer glow (pulsing when active) - contained within fixed frame
                    Circle()
                        .fill(SnapColors.laserPointer.opacity(isActive ? 0.2 : 0))
                        .frame(width: 220, height: 220)
                        .blur(radius: 40)
                        .scaleEffect(isActive ? 1.1 : 1.0)
                        .animation(
                            isActive
                                ? .easeInOut(duration: 0.8).repeatForever(autoreverses: true)
                                : .default,
                            value: isActive
                        )

                    // Button shadow glow
                    Circle()
                        .fill(SnapColors.laserPointer.opacity(isActive ? 0.5 : 0))
                        .frame(width: 180, height: 180)
                        .blur(radius: 30)

                    // Main button
                    Circle()
                        .fill(isActive ? SnapColors.laserPointer : SnapColors.tertiarySystemBackground)
                        .frame(width: 160, height: 160)
                        .overlay(
                            Circle()
                                .strokeBorder(
                                    isActive ? SnapColors.laserPointer.opacity(0.6) : SnapColors.separator,
                                    lineWidth: 2
                                )
                        )
                        .scaleEffect(isActive ? 0.95 : 1.0)

                    VStack(spacing: 8) {
                        Image(systemName: "scope")
                            .font(.system(size: 44, weight: .medium))
                            .foregroundStyle(isActive ? .white : SnapColors.laserPointer)
                            .symbolEffect(.pulse, isActive: isActive)

                        Text(buttonLabel(isActive: isActive, mode: activationMode))
                            .font(.caption.weight(.bold))
                            .foregroundStyle(isActive ? .white : SnapColors.secondaryLabel)
                            .tracking(1)
                    }
                }
                .frame(width: 220, height: 220) // Fixed frame prevents layout shift
                .animation(.spring(response: 0.25, dampingFraction: 0.6), value: isActive)
                .gesture(
                    activationMode == .hold
                        ? AnyGesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { _ in
                                    if !store.laserPointer.isActive {
                                        store.send(.laserPointer(.startPointing))
                                    }
                                }
                                .onEnded { _ in
                                    store.send(.laserPointer(.stopPointing))
                                }
                                .map { _ in () }
                          )
                        : AnyGesture(
                            TapGesture()
                                .onEnded {
                                    store.send(.laserPointer(.toggleActive))
                                }
                                .map { _ in () }
                          )
                )
                .accessibilityLabel("레이저 포인터 버튼")
                .accessibilityHint(activationMode == .hold ? "길게 누르고 있으면 활성화됩니다" : "탭하여 켜고 끕니다")

                // Sensitivity (compact)
                HStack(spacing: 8) {
                    Image(systemName: "tortoise")
                        .foregroundStyle(SnapColors.textSecondary)
                        .font(.caption2)

                    Slider(
                        value: Binding(
                            get: { Double(store.laserPointer.sensitivity) },
                            set: { store.send(.laserPointer(.setSensitivity(Float($0)))) }
                        ),
                        in: 1...50
                    )
                    .tint(SnapColors.laserPointer)

                    Image(systemName: "hare")
                        .foregroundStyle(SnapColors.textSecondary)
                        .font(.caption2)

                    Text("\(Int(store.laserPointer.sensitivity))")
                        .font(.caption2.monospacedDigit())
                        .foregroundStyle(SnapColors.textSecondary)
                        .frame(width: 24)
                }
                .padding(.horizontal)
            }
            .padding(.vertical, 12)
            .padding(.horizontal)
        }
        .padding(.horizontal)
        .alert(
            "오류",
            isPresented: Binding(
                get: { store.laserPointer.errorMessage != nil },
                set: { if !$0 { store.send(.laserPointer(.dismissError)) } }
            )
        ) {
            Button("확인") {
                store.send(.laserPointer(.dismissError))
            }
        } message: {
            Text(store.laserPointer.errorMessage ?? "")
        }
    }

    private func buttonLabel(isActive: Bool, mode: LaserPointerFeature.ActivationMode) -> String {
        if isActive {
            return "GYRO ACTIVE"
        }
        return mode == .hold ? "HOLD TO MOVE" : "TAP TO START"
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
            .font(SnapTypography.headlineSmall)
            .foregroundStyle(isPrimary ? SnapColors.textPrimary : SnapColors.textSecondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                    .fill(isPressed ? Color.accentColor.opacity(0.2) : SnapColors.backgroundElevated)
                    .overlay(
                        RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                            .strokeBorder(isPressed ? Color.accentColor.opacity(0.5) : SnapColors.border, lineWidth: isPressed ? 1 : 0.5)
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .animation(.spring(response: 0.15, dampingFraction: 0.6), value: isPressed)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            Task { @MainActor in
                                HapticManager.shared.buttonPress()
                            }
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
                .foregroundStyle(isPressed ? SnapColors.label : color)

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(SnapColors.secondaryLabel)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isPressed ? SnapColors.tertiarySystemFill : SnapColors.secondarySystemBackground)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(SnapColors.separator, lineWidth: 1)
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
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            VStack(spacing: SnapSpacing.sm) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(Color.accentColor)

                Text(label)
                    .font(SnapTypography.caption)
                    .fontWeight(.semibold)
                    .foregroundStyle(SnapColors.textTertiary)
                    .textCase(.uppercase)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.lg)
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                    .strokeBorder(SnapColors.border, lineWidth: 0.5)
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
