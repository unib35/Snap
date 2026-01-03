import ComposableArchitecture
import CoreGraphics
import Shared

@Reducer
public struct TrackpadFeature {
    @ObservableState
    public struct State: Equatable {
        public var mode: InputMode = .trackpad
        public var isTouching: Bool = false
        public var lastTouchPosition: CGPoint = .zero
        public var sensitivity: Double = 1.0
        public var scrollSensitivity: Double = 1.0
        public var isNaturalScrolling: Bool = true
        public var isTapToClick: Bool = true
        public var laserPointer: LaserPointerFeature.State = .init()

        public init() {}
    }

    public enum InputMode: String, CaseIterable, Sendable {
        case trackpad
        case laser

        public var title: String {
            switch self {
            case .trackpad: return "Trackpad"
            case .laser: return "Laser"
            }
        }
    }

    public enum Action: Equatable, Sendable {
        // Mode
        case modeChanged(InputMode)

        // Touch Events
        case touchBegan(CGPoint)
        case touchMoved(CGPoint)
        case touchEnded

        // Gestures
        case tapped
        case doubleTapped
        case twoFingerTapped
        case scrolled(deltaX: CGFloat, deltaY: CGFloat)

        // Click Buttons
        case leftClickPressed
        case leftClickReleased
        case rightClickPressed
        case rightClickReleased

        // Quick Actions
        case spotlightPressed
        case missionControlPressed

        // Settings
        case updateSettings(
            sensitivity: Double,
            scrollSensitivity: Double,
            isNaturalScrolling: Bool,
            isTapToClick: Bool
        )

        // Laser Pointer
        case laserPointer(LaserPointerFeature.Action)
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.laserPointer, action: \.laserPointer) {
            LaserPointerFeature()
        }

        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .modeChanged(let mode):
                state.mode = mode
                // 트랙패드 모드로 변경 시 레이저 포인터 중지
                if mode == .trackpad && state.laserPointer.isActive {
                    return .send(.laserPointer(.stopPointing))
                }
                return .none

            case .touchBegan(let position):
                state.isTouching = true
                state.lastTouchPosition = position
                return .none

            case .touchMoved(let position):
                guard state.isTouching else { return .none }

                let deltaX = Float(position.x - state.lastTouchPosition.x) * Float(state.sensitivity)
                let deltaY = Float(position.y - state.lastTouchPosition.y) * Float(state.sensitivity)
                state.lastTouchPosition = position

                return .run { _ in
                    await client.sendMouseMove(deltaX, deltaY)
                }

            case .touchEnded:
                state.isTouching = false
                return .none

            case .tapped:
                guard state.isTapToClick else { return .none }
                return .run { _ in
                    await client.sendMouseClick(.left, .click)
                }

            case .doubleTapped:
                return .run { _ in
                    await client.sendMouseClick(.left, .double)
                }

            case .twoFingerTapped:
                return .run { _ in
                    await client.sendMouseClick(.right, .click)
                }

            case .scrolled(let deltaX, let deltaY):
                let scrollX = Float(deltaX) * Float(state.scrollSensitivity)
                let scrollY: Float
                if state.isNaturalScrolling {
                    scrollY = Float(deltaY) * Float(state.scrollSensitivity)
                } else {
                    scrollY = -Float(deltaY) * Float(state.scrollSensitivity)
                }

                return .run { _ in
                    await client.sendScroll(scrollX, scrollY, false)
                }

            case .leftClickPressed:
                return .run { _ in
                    await client.sendMouseClick(.left, .down)
                }

            case .leftClickReleased:
                return .run { _ in
                    await client.sendMouseClick(.left, .up)
                }

            case .rightClickPressed:
                return .run { _ in
                    await client.sendMouseClick(.right, .down)
                }

            case .rightClickReleased:
                return .run { _ in
                    await client.sendMouseClick(.right, .up)
                }

            case .spotlightPressed:
                // Cmd + Space
                return .run { _ in
                    await client.sendKeyCombo([49], 0x08) // Space with Command
                }

            case .missionControlPressed:
                // Control + Up Arrow (Mission Control)
                return .run { _ in
                    await client.sendKeyCombo([126], 0x02) // Up Arrow with Control
                }

            case .updateSettings(let sensitivity, let scrollSensitivity, let isNaturalScrolling, let isTapToClick):
                state.sensitivity = sensitivity
                state.scrollSensitivity = scrollSensitivity
                state.isNaturalScrolling = isNaturalScrolling
                state.isTapToClick = isTapToClick
                return .none

            case .laserPointer:
                return .none
            }
        }
    }
}
