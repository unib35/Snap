import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct LaserPointerFeature {
    @ObservableState
    public struct State: Equatable {
        public var isActive: Bool = false
        public var isCalibrated: Bool = false
        public var sensitivity: Float = 15.0
        public var errorMessage: String?

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case toggleActive
        case startPointing
        case stopPointing
        case calibrate
        case setSensitivity(Float)
        case motionEvent(MotionEvent)
        case dismissError
    }

    @Dependency(\.connectionClient) var connectionClient

    private let motionManager = MotionManager()

    public init() {}

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
                guard motionManager.isAvailable else {
                    state.errorMessage = "자이로스코프를 사용할 수 없습니다"
                    return .none
                }

                state.isActive = true
                state.errorMessage = nil

                // 시작할 때 자동 캘리브레이션
                motionManager.calibrate()
                state.isCalibrated = true

                let manager = motionManager
                return .run { send in
                    for await event in manager.startUpdates() {
                        await send(.motionEvent(event))
                    }
                }

            case .stopPointing:
                state.isActive = false
                state.isCalibrated = false
                motionManager.stopUpdates()
                return .none

            case .calibrate:
                motionManager.calibrate()
                state.isCalibrated = true
                return .none

            case .setSensitivity(let value):
                state.sensitivity = value
                motionManager.setSensitivity(value)
                return .none

            case .motionEvent(let event):
                switch event {
                case .update(let gyroData):
                    guard state.isActive else { return .none }

                    let client = connectionClient
                    return .run { _ in
                        await client.sendGyroData(gyroData)
                    }

                case .error(let message):
                    state.errorMessage = message
                    state.isActive = false
                }
                return .none

            case .dismissError:
                state.errorMessage = nil
                return .none
            }
        }
    }
}
