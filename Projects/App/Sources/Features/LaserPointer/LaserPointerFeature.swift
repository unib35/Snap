import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct LaserPointerFeature {
    public enum ActivationMode: String, CaseIterable, Sendable {
        case hold = "Hold"
        case toggle = "Toggle"

        var displayName: String {
            switch self {
            case .hold: return "누르는 동안"
            case .toggle: return "켜기/끄기"
            }
        }

        var description: String {
            switch self {
            case .hold: return "버튼을 누르고 있는 동안 활성화"
            case .toggle: return "한 번 터치로 켜고 끄기"
            }
        }
    }

    public enum SensitivityPreset: String, CaseIterable, Sendable {
        case low
        case medium
        case high
        case custom

        var displayName: String {
            switch self {
            case .low: return "낮음"
            case .medium: return "중간"
            case .high: return "높음"
            case .custom: return "사용자 정의"
            }
        }

        var value: Float {
            switch self {
            case .low: return 8.0
            case .medium: return 15.0
            case .high: return 30.0
            case .custom: return 15.0
            }
        }

        static func from(sensitivity: Float) -> SensitivityPreset {
            switch sensitivity {
            case 8.0: return .low
            case 15.0: return .medium
            case 30.0: return .high
            default: return .custom
            }
        }
    }

    @ObservableState
    public struct State: Equatable {
        public var isActive: Bool = false
        public var isCalibrated: Bool = false
        public var sensitivity: Float = 15.0
        public var activationMode: ActivationMode = .hold
        public var showCalibrationGuide: Bool = false
        public var calibrationStep: Int = 0
        @Presents public var alert: AlertState<Action.Alert>?

        // Power Saving Mode
        public var isInPowerSavingMode: Bool = false

        public var sensitivityPreset: SensitivityPreset {
            SensitivityPreset.from(sensitivity: sensitivity)
        }

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case toggleActive
        case startPointing
        case stopPointing
        case calibrate
        case setSensitivity(Float)
        case setSensitivityPreset(SensitivityPreset)
        case setActivationMode(ActivationMode)
        case showCalibrationGuide
        case dismissCalibrationGuide
        case calibrationStepCompleted
        case motionEvent(MotionEvent)
        case alert(PresentationAction<Alert>)
        case updatePowerSavingMode(Bool)

        @CasePathable
        public enum Alert: Equatable, Sendable {
            case dismiss
        }
    }

    @Dependency(\.connectionClient) var connectionClient
    @Dependency(\.motionClient) var motionClient

    public init() {}

    private enum CancelID {
        case motion
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .toggleActive:
                if state.isActive {
                    return .send(.stopPointing)
                } else {
                    return .send(.startPointing)
                }

            case .startPointing:
                guard motionClient.isAvailable() else {
                    state.alert = AppError.general("자이로스코프를 사용할 수 없습니다")
                        .toSimpleAlertState(dismiss: .dismiss)
                    return .none
                }

                state.isActive = true

                // 시작할 때 자동 캘리브레이션
                motionClient.calibrate()
                state.isCalibrated = true

                return .run { [motionClient] send in
                    for await event in motionClient.startUpdates() {
                        await send(.motionEvent(event))
                    }
                }
                .cancellable(id: CancelID.motion)

            case .stopPointing:
                state.isActive = false
                state.isCalibrated = false
                motionClient.stopUpdates()
                return .cancel(id: CancelID.motion)

            case .calibrate:
                motionClient.calibrate()
                state.isCalibrated = true
                state.calibrationStep = 3 // 캘리브레이션 완료
                return .none

            case .showCalibrationGuide:
                state.showCalibrationGuide = true
                state.calibrationStep = 0
                return .none

            case .dismissCalibrationGuide:
                state.showCalibrationGuide = false
                state.calibrationStep = 0
                return .none

            case .calibrationStepCompleted:
                state.calibrationStep += 1
                if state.calibrationStep >= 3 {
                    // 가이드 완료 시 자동으로 캘리브레이션 수행
                    motionClient.calibrate()
                    state.isCalibrated = true
                    state.showCalibrationGuide = false
                }
                return .none

            case .setSensitivityPreset(let preset):
                guard preset != .custom else { return .none }
                state.sensitivity = preset.value
                motionClient.setSensitivity(preset.value)
                return .none

            case .setSensitivity(let value):
                state.sensitivity = value
                motionClient.setSensitivity(value)
                return .none

            case .setActivationMode(let mode):
                state.activationMode = mode
                // 모드 변경 시 활성화 상태 초기화
                if state.isActive {
                    return .send(.stopPointing)
                }
                return .none

            case .motionEvent(let event):
                switch event {
                case .update(let gyroData):
                    guard state.isActive else { return .none }

                    return .run { [connectionClient] _ in
                        await connectionClient.sendGyroData(gyroData)
                    }

                case .error(let message):
                    state.alert = AppError.general(message)
                        .toSimpleAlertState(dismiss: .dismiss)
                    state.isActive = false
                }
                return .none

            case .alert:
                return .none

            case .updatePowerSavingMode(let isInPowerSavingMode):
                state.isInPowerSavingMode = isInPowerSavingMode
                motionClient.setLowPowerMode(isInPowerSavingMode)
                return .none
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
