import ComposableArchitecture
import Foundation

@Reducer
public struct PresenterFeature {
    // MARK: - Timer Mode

    public enum TimerMode: String, CaseIterable, Sendable {
        case countUp = "Count Up"
        case countDown = "Count Down"
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

        // Haptic feedback intervals (in seconds)
        public var hapticWarningInterval: Int = 60 // 1 minute warning

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

        // Haptic
        case triggerHaptic(HapticType)
    }

    public enum HapticType: Equatable, Sendable {
        case slideChange
        case warning
        case overtime
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
                    await send(.triggerHaptic(.slideChange))
                }

            case .previousSlide:
                if state.slideNumber > 1 {
                    state.slideNumber -= 1
                }
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.leftArrow, .press, 0)
                    await send(.triggerHaptic(.slideChange))
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

                // Check for haptic warnings
                let totalTarget = state.targetMinutes * 60
                let elapsed = state.elapsedSeconds

                if state.timerMode == .countDown {
                    // Overtime warning
                    if elapsed == totalTarget {
                        return .send(.triggerHaptic(.overtime))
                    }
                    // Warning at intervals
                    let remaining = totalTarget - elapsed
                    if remaining > 0, remaining.isMultiple(of: state.hapticWarningInterval) {
                        return .send(.triggerHaptic(.warning))
                    }
                } else {
                    // Count up mode - warning every minute
                    if elapsed > 0, elapsed.isMultiple(of: 60) {
                        return .send(.triggerHaptic(.warning))
                    }
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

            case .triggerHaptic:
                // Haptic feedback is handled in the View
                return .none
            }
        }
    }
}
