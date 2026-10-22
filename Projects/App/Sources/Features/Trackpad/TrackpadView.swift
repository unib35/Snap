import ComposableArchitecture
import Shared
import SwiftUI
import UIKit

public struct TrackpadView: View {
    @Bindable var store: StoreOf<TrackpadFeature>
    @Environment(\.layoutMode) private var layoutMode

    public init(store: StoreOf<TrackpadFeature>) {
        self.store = store
    }

    @State private var isGestureHelpPresented = false

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
        Picker("입력 방식", selection: $store.mode.sending(\.modeChanged)) {
            ForEach(TrackpadFeature.InputMode.allCases, id: \.self) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .trackpadAreaConstraint()
    }

    // MARK: - Trackpad Content

    @ViewBuilder
    private var trackpadContent: some View {
        iPadOptimizedContainer {
            VStack(spacing: 0) {
                // Touch Area
                TrackpadTouchArea(store: store)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .trackpadAreaConstraint()

                clickButtons
                    .padding(.top, layoutMode == .compact ? 12 : 16)
                    .padding(.bottom, 8)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    // MARK: - Laser Content

    @ViewBuilder
    private var laserContent: some View {
        iPadOptimizedContainer {
            VStack(spacing: layoutMode == .compact ? 12 : 16) {
                // Scroll independently while keeping click buttons accessible
                ScrollView {
                    LaserControlArea(store: store)
                }
                .frame(maxHeight: .infinity)

                clickButtons
                    .padding(.bottom, 8)
            }
        }
        .transition(.opacity.combined(with: .scale(scale: 0.98)))
    }

    private var clickButtons: some View {
        HStack(spacing: layoutMode == .compact ? 12 : 16) {
            ClickButton(label: "왼쪽 클릭") {
                store.send(.leftClickPressed)
            } onRelease: {
                store.send(.leftClickReleased)
            }
            ClickButton(label: "오른쪽 클릭") {
                store.send(.rightClickPressed)
            } onRelease: {
                store.send(.rightClickReleased)
            }
        }
        .frame(height: layoutMode == .compact ? 56 : 64)
        .padding(.horizontal)
    }

    // MARK: - Quick Actions

    private var quickActions: some View {
        HStack {
            Button { store.send(.missionControlPressed) } label: {
                Label("열린 창 보기", systemImage: "rectangle.3.group")
                    .frame(minHeight: 44)
            }
            Spacer()
            Button { isGestureHelpPresented = true } label: {
                Label("사용법", systemImage: "questionmark.circle")
                    .frame(minHeight: 44)
            }
        }
        .font(.subheadline.weight(.medium))
        .trackpadAreaConstraint()
        .sheet(isPresented: $isGestureHelpPresented) {
            NavigationStack {
                List {
                    if store.mode == .laser {
                        Section("기기를 움직여 조작") {
                            Text("누르는 동안: 제어 버튼을 누른 채 기기를 움직이고, 손을 떼면 멈춥니다.")
                            Text("켜기/끄기: 제어 버튼을 탭하여 시작하고, 다시 탭하여 멈춥니다.")
                        }
                        Section("클릭과 감도") {
                            Text("왼쪽 클릭과 오른쪽 클릭 버튼은 트랙패드와 동일하게 동작합니다.")
                            Text("포인터가 너무 빠르면 감도를 낮추세요.")
                        }
                    } else {
                        Section("트랙패드") {
                            Label("한 손가락으로 움직여 포인터 이동", systemImage: "hand.draw")
                            Label("한 번 탭하여 클릭 · 두 번 탭하여 더블 클릭", systemImage: "hand.tap")
                            Label("두 손가락으로 움직여 스크롤", systemImage: "hand.draw.fill")
                            Label("두 손가락으로 탭하여 오른쪽 클릭", systemImage: "hand.tap.fill")
                            Label("두 손가락을 벌리거나 모아 확대·축소", systemImage: "arrow.up.left.and.arrow.down.right")
                        }
                        Section("드래그") {
                            Text("왼쪽 클릭 버튼을 누른 채 다른 손가락으로 터치 영역을 움직이세요.")
                        }
                    }
                }
                .navigationTitle(store.mode == .laser ? "레이저 사용법" : "트랙패드 사용법")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("완료") { isGestureHelpPresented = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Trackpad Touch Area

struct TrackpadTouchArea: View {
    let store: StoreOf<TrackpadFeature>

    var body: some View {
        ZStack {
            // Background
            RoundedRectangle(cornerRadius: SnapCornerRadius.xxl)
                .fill(SnapColors.backgroundElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: SnapCornerRadius.xxl)
                        .strokeBorder(SnapColors.border, lineWidth: 0.5)
                )

            VStack(spacing: 10) {
                Image(systemName: "hand.draw")
                    .font(.title2)
                Text("손가락으로 움직여 조작")
                    .font(.subheadline)
                Text("탭하여 클릭 · 두 손가락으로 스크롤")
                    .font(.caption)
            }
            .foregroundStyle(SnapColors.textSecondary)
            .multilineTextAlignment(.center)
            .padding()
            .opacity(store.isTouching ? 0 : 1)
            .accessibilityHidden(true)

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

        VStack(spacing: 20) {
            Picker("레이저 작동 방식", selection: Binding(
                get: { store.laserPointer.activationMode },
                set: { store.send(.laserPointer(.setActivationMode($0))) }
            )) {
                ForEach(LaserPointerFeature.ActivationMode.allCases, id: \.self) { mode in
                    Text(mode.displayName).tag(mode)
                }
            }
            .pickerStyle(.segmented)

            Text(activationMode == .hold
                 ? "아래 버튼을 누른 채 기기를 움직이세요."
                 : "아래 버튼으로 켠 뒤 기기를 움직이세요. 다시 탭하면 멈춥니다.")
                .font(.subheadline)
                .foregroundStyle(SnapColors.textSecondary)
                .multilineTextAlignment(.center)

            VStack(spacing: 12) {
                Image(systemName: "scope")
                    .font(.largeTitle)
                Text(buttonLabel(isActive: isActive, mode: activationMode))
                    .font(.headline)
                    .multilineTextAlignment(.center)
            }
            .foregroundStyle(isActive ? SnapColors.laserPointer : SnapColors.textPrimary)
            .padding(24)
            .frame(maxWidth: .infinity, minHeight: 120)
            .background(isActive ? SnapColors.laserPointer.opacity(0.12) : SnapColors.backgroundTertiary)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
            .contentShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
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
            .accessibilityLabel("레이저 포인터")
            .accessibilityValue(isActive ? "이동 중" : "대기 중")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { store.send(.laserPointer(.toggleActive)) }
            .accessibilityHint("이중 탭하여 포인터 이동을 켜거나 끕니다")

            VStack(spacing: 8) {
                HStack {
                    Text("포인터 감도")
                    Spacer()
                    Text("\(Int(store.laserPointer.sensitivity))")
                        .monospacedDigit()
                        .foregroundStyle(SnapColors.textSecondary)
                }
                .font(.subheadline)
                Slider(
                    value: Binding(
                        get: { Double(store.laserPointer.sensitivity) },
                        set: { store.send(.laserPointer(.setSensitivity(Float($0)))) }
                    ),
                    in: 1...50
                )
                .accessibilityLabel("포인터 감도")
                .accessibilityValue("\(Int(store.laserPointer.sensitivity))")
            }
        }
        .padding(20)
        .cardStyle(cornerRadius: SnapCornerRadius.xxl)
        .padding(.horizontal)
        .alert($store.scope(state: \.laserPointer.alert, action: \.laserPointer.alert))
    }

    private func buttonLabel(isActive: Bool, mode: LaserPointerFeature.ActivationMode) -> String {
        if isActive {
            return mode == .hold ? "손을 떼면 멈춤" : "탭하여 멈추기"
        }
        return mode == .hold ? "누른 채 움직이기" : "탭하여 시작"
    }
}

// MARK: - Click Button

struct ClickButton: View {
    let label: String
    let onPress: () -> Void
    let onRelease: () -> Void

    @State private var isPressed = false

    var body: some View {
        Text(label)
            .font(SnapTypography.headlineSmall)
            .foregroundStyle(SnapColors.textPrimary)
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
            .accessibilityLabel(label)
            .accessibilityHint("길게 눌러 클릭을 유지할 수 있습니다")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { onPress(); onRelease() }
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
