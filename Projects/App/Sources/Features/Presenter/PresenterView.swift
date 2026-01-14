import AudioToolbox
import ComposableArchitecture
import SwiftUI

// MARK: - Presenter Section (for ProductivityView)

public struct PresenterSection: View {
    @Bindable var store: StoreOf<PresenterFeature>
    @State private var isOvertimeFlashing = false

    public init(store: StoreOf<PresenterFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "rectangle.inset.filled.and.person.filled")
                    .font(.headline)
                    .foregroundStyle(Color.accentColor)

                Text("프레젠테이션")
                    .font(.headline)

                Spacer()

                if store.isPresenting {
                    Text("Slide \(store.slideNumber)")
                        .font(.caption)
                        .foregroundStyle(SnapColors.textSecondary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SnapColors.tertiarySystemBackground)
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
        .background(SnapColors.secondarySystemBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .onChange(of: store.isOvertime) { _, isOvertime in
            if isOvertime {
                startOvertimeFlashing()
                triggerAlert(level: .overtime)
            } else {
                isOvertimeFlashing = false
            }
        }
        .onChange(of: store.triggeredAlerts) { oldValue, newValue in
            // Check for new alerts
            let newAlerts = newValue.subtracting(oldValue)
            for alert in newAlerts {
                switch alert {
                case 300:
                    triggerAlert(level: .fiveMinutes)
                case 60:
                    triggerAlert(level: .oneMinute)
                default:
                    break
                }
            }
        }
    }

    // MARK: - Alert Handling

    private func triggerAlert(level: PresenterFeature.AlertLevel) {
        let alertType = store.alertType

        // Haptic feedback
        if alertType == .vibration || alertType == .both {
            switch level {
            case .slideChange:
                HapticManager.shared.lightImpact()
            case .fiveMinutes:
                HapticManager.shared.warning()
            case .oneMinute:
                HapticManager.shared.warning()
                HapticManager.shared.warning()
            case .overtime:
                HapticManager.shared.error()
            }
        }

        // Sound feedback
        if alertType == .sound || alertType == .both {
            switch level {
            case .slideChange:
                break  // No sound for slide change
            case .fiveMinutes:
                AudioServicesPlaySystemSound(1007)  // SMS Received
            case .oneMinute:
                AudioServicesPlaySystemSound(1005)  // Calendar Alert
            case .overtime:
                AudioServicesPlaySystemSound(1521)  // Strong Vibration + Sound
            }
        }
    }

    private func startOvertimeFlashing() {
        isOvertimeFlashing = true
        // Flash animation is handled by the timer display
    }

    // MARK: - Setup Controls

    @ViewBuilder
    private var setupControls: some View {
        VStack(spacing: 16) {
            // Timer Mode Picker
            HStack {
                Text("타이머 모드")
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.textSecondary)

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
                        .foregroundStyle(SnapColors.textSecondary)

                    Spacer()

                    Stepper(
                        "\(store.targetMinutes)분",
                        value: $store.targetMinutes.sending(\.setTargetMinutes),
                        in: 1...120
                    )
                    .frame(width: 150)
                }

                // Alert Settings Section
                alertSettingsSection
            }

            // Start Button
            Button {
                store.send(.startPresentation)
                Task { @MainActor in
                    HapticManager.shared.mediumImpact()
                }
            } label: {
                HStack {
                    Image(systemName: "play.fill")
                    Text("발표 시작")
                }
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - Alert Settings Section

    @ViewBuilder
    private var alertSettingsSection: some View {
        VStack(spacing: 12) {
            Divider()
                .padding(.vertical, 4)

            // Alert Type Picker
            HStack {
                Text("알림 방식")
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.textSecondary)

                Spacer()

                Picker("", selection: $store.alertType.sending(\.setAlertType)) {
                    ForEach(PresenterFeature.AlertType.allCases, id: \.self) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .pickerStyle(.menu)
            }

            // Alert Timing Toggles
            VStack(spacing: 8) {
                alertToggleRow(
                    title: "5분 전 알림",
                    isOn: store.fiveMinuteAlert,
                    action: { store.send(.toggleFiveMinuteAlert) }
                )

                alertToggleRow(
                    title: "1분 전 알림",
                    isOn: store.oneMinuteAlert,
                    action: { store.send(.toggleOneMinuteAlert) }
                )

                alertToggleRow(
                    title: "시간 초과 알림",
                    isOn: store.overtimeAlert,
                    action: { store.send(.toggleOvertimeAlert) }
                )
            }
        }
    }

    @ViewBuilder
    private func alertToggleRow(title: String, isOn: Bool, action: @escaping () -> Void) -> some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(SnapColors.textSecondary)

            Spacer()

            Toggle("", isOn: Binding(
                get: { isOn },
                set: { _ in action() }
            ))
            .labelsHidden()
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
                .foregroundStyle(store.isOvertime ? SnapColors.warning : .primary)
                .opacity(store.isOvertime && isOvertimeFlashing ? 0.3 : 1.0)
                .animation(
                    store.isOvertime
                        ? .easeInOut(duration: 0.5).repeatForever(autoreverses: true)
                        : .default,
                    value: store.isOvertime
                )

            // Progress Bar (for countdown)
            if store.timerMode == .countDown {
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(SnapColors.tertiarySystemBackground)
                            .frame(height: 8)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(progressColor)
                            .frame(width: geometry.size.width * store.progress, height: 8)
                    }
                }
                .frame(height: 8)

                if store.isOvertime {
                    HStack(spacing: 4) {
                        Image(systemName: "exclamationmark.triangle.fill")
                        Text("시간 초과!")
                    }
                    .font(.caption)
                    .foregroundStyle(SnapColors.warning)
                    .fontWeight(.bold)
                    .opacity(isOvertimeFlashing ? 0.5 : 1.0)
                    .animation(
                        .easeInOut(duration: 0.5).repeatForever(autoreverses: true),
                        value: isOvertimeFlashing
                    )
                }
            }
        }
        .padding()
        .background(
            store.isOvertime
                ? SnapColors.warning.opacity(0.1)
                : SnapColors.tertiarySystemBackground
        )
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            store.isOvertime
                ? RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(SnapColors.warning.opacity(0.5), lineWidth: 2)
                : nil
        )
    }

    private var progressColor: Color {
        if store.progress >= 0.9 {
            return SnapColors.warning
        } else if store.progress >= 0.7 {
            return SnapColors.warning.opacity(0.7)
        }
        return SnapColors.success
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
                Task { @MainActor in
                    HapticManager.shared.lightImpact()
                }
            }

            // Next Slide
            SlideButton(
                icon: "chevron.right",
                label: "다음",
                color: .accentColor
            ) {
                store.send(.nextSlide)
                Task { @MainActor in
                    HapticManager.shared.lightImpact()
                }
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
                Task { @MainActor in
                    HapticManager.shared.mediumImpact()
                }
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
                Task { @MainActor in
                    HapticManager.shared.lightImpact()
                }
            }

            // End Presentation
            ControlButton(
                icon: "stop.fill",
                label: "종료",
                isActive: false,
                isDestructive: true
            ) {
                store.send(.endPresentation)
                Task { @MainActor in
                    HapticManager.shared.mediumImpact()
                }
            }
        }
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
                    .foregroundStyle(SnapColors.textSecondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(SnapColors.tertiarySystemBackground)
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
                    .foregroundStyle(SnapColors.textSecondary)
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
        if isDestructive { return SnapColors.destructive }
        if isActive { return .accentColor }
        return .primary
    }

    private var backgroundColor: Color {
        if isActive { return Color.accentColor.opacity(0.15) }
        return SnapColors.tertiarySystemBackground
    }

    private var borderColor: Color {
        if isActive { return Color.accentColor.opacity(0.3) }
        return SnapColors.separator
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
                        .foregroundStyle(store.isOvertime ? SnapColors.warning : .white)
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
                                Task { @MainActor in
                                    HapticManager.shared.lightImpact()
                                }
                            }

                        // Next (Right Half)
                        Color.clear
                            .contentShape(Rectangle())
                            .onTapGesture {
                                store.send(.nextSlide)
                                Task { @MainActor in
                                    HapticManager.shared.lightImpact()
                                }
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
                                .foregroundStyle(store.isScreenBlank ? Color.accentColor : .white)
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
                                .foregroundStyle(SnapColors.destructive)
                        }
                    }
                    .padding(.bottom, 60)
                }
            }
        }
        .statusBarHidden()
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
