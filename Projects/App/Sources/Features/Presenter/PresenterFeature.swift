import ComposableArchitecture
import Foundation

@Reducer
public struct PresenterFeature {
    // MARK: - Timer Mode

    public enum TimerMode: String, CaseIterable, Sendable {
        case countUp = "Count Up"
        case countDown = "Count Down"
    }

    // MARK: - Alert Type

    public enum AlertType: String, CaseIterable, Sendable {
        case vibration = "진동"
        case sound = "사운드"
        case both = "진동 + 사운드"
        case none = "없음"
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var isPresenting: Bool = false
        public var timerMode: TimerMode = .countUp
        public var elapsedSeconds: Int = 0
        public var targetMinutes: Int = 5
        public var isTimerRunning: Bool = false
        public var slideNumber: Int = 1
        public var isScreenBlank: Bool = false

        // Alert settings
        public var alertType: AlertType = .vibration
        public var fiveMinuteAlert: Bool = true
        public var oneMinuteAlert: Bool = true
        public var overtimeAlert: Bool = true

        // Tracking which alerts have been triggered
        public var triggeredAlerts: Set<Int> = []

        // Auto slide
        public var isAutoSlideEnabled: Bool = false
        public var autoSlideInterval: Int = 30  // seconds

        public init() {}

        // Computed properties
        public var displayTime: String {
            let minutes = elapsedSeconds / 60
            let seconds = elapsedSeconds % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        public var remainingTime: String {
            let totalSeconds = targetMinutes * 60
            let remaining = max(0, totalSeconds - elapsedSeconds)
            let minutes = remaining / 60
            let seconds = remaining % 60
            return String(format: "%02d:%02d", minutes, seconds)
        }

        public var isOvertime: Bool {
            timerMode == .countDown && elapsedSeconds >= targetMinutes * 60
        }

        public var progress: Double {
            guard timerMode == .countDown, targetMinutes > 0 else { return 0 }
            return min(1.0, Double(elapsedSeconds) / Double(targetMinutes * 60))
        }
    }

    // MARK: - Action

    public enum Action: Equatable, Sendable {
        // Slide Navigation
        case nextSlide
        case previousSlide

        // Timer
        case startTimer
        case stopTimer
        case resetTimer
        case timerTick
        case setTimerMode(TimerMode)
        case setTargetMinutes(Int)

        // Presentation
        case startPresentation
        case endPresentation
        case toggleScreenBlank

        // Alert Settings
        case setAlertType(AlertType)
        case toggleFiveMinuteAlert
        case toggleOneMinuteAlert
        case toggleOvertimeAlert

        // Haptic/Sound
        case triggerAlert(AlertLevel)

        // Auto Slide
        case toggleAutoSlide
        case setAutoSlideInterval(Int)
    }

    public enum AlertLevel: Equatable, Sendable {
        case slideChange
        case fiveMinutes    // 5분 전 알림
        case oneMinute      // 1분 전 알림
        case overtime       // 시간 초과 알림
    }

    // MARK: - Dependencies

    @Dependency(\.connectionClient) var connectionClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    // MARK: - Cancel ID

    private enum CancelID {
        case timer
    }

    // MARK: - Key Codes

    private enum KeyCode {
        static let leftArrow: UInt32 = 123
        static let rightArrow: UInt32 = 124
        static let bKey: UInt32 = 11
    }

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .nextSlide:
                state.slideNumber += 1
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.rightArrow, .press, 0)
                    await send(.triggerAlert(.slideChange))
                }

            case .previousSlide:
                if state.slideNumber > 1 {
                    state.slideNumber -= 1
                }
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.leftArrow, .press, 0)
                    await send(.triggerAlert(.slideChange))
                }

            case .startTimer:
                state.isTimerRunning = true
                return .run { [clock] send in
                    for await _ in clock.timer(interval: .seconds(1)) {
                        await send(.timerTick)
                    }
                }
                .cancellable(id: CancelID.timer)

            case .stopTimer:
                state.isTimerRunning = false
                return .cancel(id: CancelID.timer)

            case .resetTimer:
                state.elapsedSeconds = 0
                state.slideNumber = 1
                return .none

            case .timerTick:
                state.elapsedSeconds += 1

                // Check for alerts (countdown mode only)
                guard state.timerMode == .countDown else { return .none }

                let totalTarget = state.targetMinutes * 60
                let elapsed = state.elapsedSeconds
                let remaining = totalTarget - elapsed

                // 시간 초과 알림
                if elapsed == totalTarget,
                   state.overtimeAlert,
                   !state.triggeredAlerts.contains(0) {
                    state.triggeredAlerts.insert(0)
                    return .send(.triggerAlert(.overtime))
                }

                // 5분 전 알림 (300초)
                if remaining == 300,
                   state.fiveMinuteAlert,
                   !state.triggeredAlerts.contains(300) {
                    state.triggeredAlerts.insert(300)
                    return .send(.triggerAlert(.fiveMinutes))
                }

                // 1분 전 알림 (60초)
                if remaining == 60,
                   state.oneMinuteAlert,
                   !state.triggeredAlerts.contains(60) {
                    state.triggeredAlerts.insert(60)
                    return .send(.triggerAlert(.oneMinute))
                }

                return .none

            case .setTimerMode(let mode):
                state.timerMode = mode
                return .none

            case .setTargetMinutes(let minutes):
                state.targetMinutes = max(1, min(120, minutes))
                return .none

            case .startPresentation:
                state.isPresenting = true
                state.elapsedSeconds = 0
                state.slideNumber = 1
                state.isScreenBlank = false
                state.triggeredAlerts = []  // Reset triggered alerts
                return .send(.startTimer)

            case .endPresentation:
                state.isPresenting = false
                state.isScreenBlank = false
                return .send(.stopTimer)

            case .toggleScreenBlank:
                state.isScreenBlank.toggle()
                return .run { [connectionClient] _ in
                    // B key blanks/unblanks screen in PowerPoint/Keynote
                    await connectionClient.sendKeyEvent(KeyCode.bKey, .press, 0)
                }

            // Alert Settings
            case .setAlertType(let alertType):
                state.alertType = alertType
                return .none

            case .toggleFiveMinuteAlert:
                state.fiveMinuteAlert.toggle()
                return .none

            case .toggleOneMinuteAlert:
                state.oneMinuteAlert.toggle()
                return .none

            case .toggleOvertimeAlert:
                state.overtimeAlert.toggle()
                return .none

            case .triggerAlert:
                // Alert (haptic/sound) is handled in the View
                return .none

            case .toggleAutoSlide:
                state.isAutoSlideEnabled.toggle()
                return .none

            case .setAutoSlideInterval(let interval):
                state.autoSlideInterval = max(5, min(120, interval))
                return .none
            }
        }
    }
}
