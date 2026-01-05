import ComposableArchitecture
import SwiftUI

// MARK: - Presenter Section (for ProductivityView)

public struct PresenterSection: View {
    @Bindable var store: StoreOf<PresenterFeature>

    public init(store: StoreOf<PresenterFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
                    .font(.headline)
                    .foregroundStyle(.orange)

                Text("프레젠테이션")
                    .font(.headline)

                Spacer()

                if store.isPresenting {
                    Text("Slide \(store.slideNumber)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color(.tertiarySystemBackground))
                        .clipShape(Capsule())
                }
            }

            if store.isPresenting {
                // Presentation Mode
                presentationControls
            } else {
                // Setup Mode
                setupControls
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: store.isOvertime) { _, isOvertime in
            if isOvertime {
                triggerHaptic(.error)
            }
        }
    }

    // MARK: - Setup Controls

    @ViewBuilder
    private var setupControls: some View {
        VStack(spacing: 16) {
            // Timer Mode Picker
            HStack {
                Text("타이머 모드")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()

                Picker("", selection: $store.timerMode.sending(\.setTimerMode)) {
                    ForEach(PresenterFeature.TimerMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            // Target Time (for countdown mode)
            if store.timerMode == .countDown {
                HStack {
                    Text("목표 시간")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Spacer()

                    Stepper(
                        "\(store.targetMinutes)분",
                        value: $store.targetMinutes.sending(\.setTargetMinutes),
                        in: 1...120
                    )
                    .frame(width: 150)
                }
            }

            // Start Button
            Button {
                store.send(.startPresentation)
                triggerHaptic(.medium)
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("발표 시작")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.orange)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Presentation Controls

    @ViewBuilder
    private var presentationControls: some View {
        VStack(spacing: 20) {
            // Timer Display
            timerDisplay

            // Large Slide Navigation Buttons
            slideNavigationButtons

            // Control Bar
            controlBar
        }
    }

    @ViewBuilder
    private var timerDisplay: some View {
        VStack(spacing: 8) {
            // Time
            Text(store.timerMode == .countDown ? store.remainingTime : store.displayTime)
                .font(.system(size: 48, weight: .bold, design: .monospaced))
                .foregroundStyle(store.isOvertime ? .red : .primary)

            // Progress Bar (for countdown)
            if store.timerMode == .countDown {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color(.tertiarySystemBackground))
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * store.progress, height: 8)
                    }
                }
                .frame(height: 8)

                if store.isOvertime {
                    Text("시간 초과!")
                        .font(.caption)
                        .foregroundStyle(.red)
                        .fontWeight(.bold)
                }
            }
        }
        .padding()
        .background(Color(.tertiarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var progressColor: Color {
        if store.progress >= 0.9 {
            return .red
        } else if store.progress >= 0.7 {
            return .orange
        }
        return .green
    }

    @ViewBuilder
    private var slideNavigationButtons: some View {
        HStack(spacing: 16) {
            // Previous Slide
            SlideButton(
                icon: "chevron.left",
                label: "이전",
                color: .secondary
            ) {
                store.send(.previousSlide)
                triggerHaptic(.light)
            }

            // Next Slide
            SlideButton(
                icon: "chevron.right",
                label: "다음",
                color: .orange
            ) {
                store.send(.nextSlide)
                triggerHaptic(.light)
            }
        }
        .frame(height: 120)
    }

    @ViewBuilder
    private var controlBar: some View {
        HStack(spacing: 16) {
            // Screen Blank Button
            ControlButton(
                icon: store.isScreenBlank ? "rectangle.slash" : "rectangle",
                label: "화면 끄기",
                isActive: store.isScreenBlank
            ) {
                store.send(.toggleScreenBlank)
                triggerHaptic(.medium)
            }

            // Timer Pause/Resume
            ControlButton(
                icon: store.isTimerRunning ? "pause.fill" : "play.fill",
                label: store.isTimerRunning ? "일시정지" : "재개",
                isActive: false
            ) {
                if store.isTimerRunning {
                    store.send(.stopTimer)
                } else {
                    store.send(.startTimer)
                }
                triggerHaptic(.light)
            }

            // End Presentation
            ControlButton(
                icon: "stop.fill",
                label: "종료",
                isActive: false,
                isDestructive: true
            ) {
                store.send(.endPresentation)
                triggerHaptic(.medium)
            }
        }
    }

    // MARK: - Haptic Feedback

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }

    private func triggerHaptic(_ type: UINotificationFeedbackGenerator.FeedbackType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(type)
    }
}

// MARK: - Slide Button

struct SlideButton: View {
    let icon: String
    let label: String
    let color: Color
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 36, weight: .bold))
                    .foregroundStyle(color)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(color.opacity(0.3), lineWidth: 2)
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = true
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Control Button

struct ControlButton: View {
    let icon: String
    let label: String
    let isActive: Bool
    var isDestructive: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(foregroundColor)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 60)
            .background(backgroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(borderColor, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private var foregroundColor: Color {
        if isDestructive { return .red }
        if isActive { return .orange }
        return .primary
    }

    private var backgroundColor: Color {
        if isActive { return Color.orange.opacity(0.15) }
        return Color(.tertiarySystemBackground)
    }

    private var borderColor: Color {
        if isActive { return Color.orange.opacity(0.3) }
        return Color(.separator)
    }
}

// MARK: - Full Screen Presenter View

public struct PresenterFullScreenView: View {
    @Bindable var store: StoreOf<PresenterFeature>
    @Environment(\.dismiss) private var dismiss

    public init(store: StoreOf<PresenterFeature>) {
        self.store = store
    }

    public var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                Color.black.ignoresSafeArea()

                VStack(spacing: 0) {
                    // Timer
                    Text(store.timerMode == .countDown ? store.remainingTime : store.displayTime)
                        .font(.system(size: 72, weight: .bold, design: .monospaced))
                        .foregroundStyle(store.isOvertime ? .red : .white)
                        .padding(.top, 60)

                    // Slide Number
                    Text("Slide \(store.slideNumber)")
                        .font(.title2)
                        .foregroundStyle(.white.opacity(0.6))
                        .padding(.top, 16)

                    Spacer()

                    // Large Touch Areas for Slide Navigation
                    HStack(spacing: 0) {
                        // Previous (Left Half)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.previousSlide)
                                triggerHaptic(.light)
                            }

                        // Next (Right Half)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.nextSlide)
                                triggerHaptic(.light)
                            }
                    }
                    .frame(height: geometry.size.height * 0.5)

                    Spacer()

                    // Control Bar
                    HStack(spacing: 32) {
                        // Screen Blank
                        Button {
                            store.send(.toggleScreenBlank)
                        } label: {
                            Image(systemName: store.isScreenBlank ? "rectangle.slash" : "rectangle")
                                .font(.title)
                                .foregroundStyle(store.isScreenBlank ? .orange : .white)
                        }

                        // Timer Control
                        Button {
                            if store.isTimerRunning {
                                store.send(.stopTimer)
                            } else {
                                store.send(.startTimer)
                            }
                        } label: {
                            Image(systemName: store.isTimerRunning ? "pause.fill" : "play.fill")
                                .font(.title)
                                .foregroundStyle(.white)
                        }

                        // End
                        Button {
                            store.send(.endPresentation)
                            dismiss()
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title)
                                .foregroundStyle(.red)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .statusBarHidden()
    }

    private func triggerHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

#Preview("Section") {
    PresenterSection(
        store: Store(initialState: PresenterFeature.State()) {
            PresenterFeature()
        }
    )
    .padding()
}

#Preview("Full Screen") {
    var state = PresenterFeature.State()
    state.isPresenting = true
    return PresenterFullScreenView(
        store: Store(initialState: state) {
            PresenterFeature()
        }
    )
}
