import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct LaserPointerFeature {
    public enum ActivationMode: String, CaseIterable, Sendable {
        case hold = "Hold"
        case toggle = "Toggle"
    }

    @ObservableState
    public struct State: Equatable {
        public var isActive: Bool = false
        public var isCalibrated: Bool = false
        public var sensitivity: Float = 15.0
        public var activationMode: ActivationMode = .hold
        @Presents public var alert: AlertState<Action.Alert>?

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case toggleActive
        case startPointing
        case stopPointing
        case calibrate
        case setSensitivity(Float)
        case setActivationMode(ActivationMode)
        case motionEvent(MotionEvent)
        case alert(PresentationAction<Alert>)

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
            }
        }
        .ifLet(\.$alert, action: \.alert)
    }
}
