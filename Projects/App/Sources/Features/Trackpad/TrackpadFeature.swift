import ComposableArchitecture
import CoreGraphics
import Shared

// MARK: - TrackpadFeature

/// 트랙패드 입력 및 레이저 포인터 기능을 관리하는 TCA Reducer.
///
/// `TrackpadFeature`는 Snap 앱의 핵심 입력 기능을 담당합니다.
/// 터치 기반 트랙패드 모드와 자이로스코프 기반 레이저 포인터 모드를 지원합니다.
///
/// ## 주요 기능
/// - **트랙패드 모드**: 터치 제스처를 마우스 입력으로 변환
/// - **레이저 포인터 모드**: 디바이스 움직임을 커서 이동으로 변환
/// - **음성 타이핑**: 음성 인식을 통한 텍스트 입력
/// - **배터리 절약**: 저전력 모드에서 전송 빈도 감소
///
/// ## 사용 예제
/// ```swift
/// struct ContentView: View {
///     let store: StoreOf<TrackpadFeature>
///
///     var body: some View {
///         TrackpadView(store: store)
///     }
/// }
/// ```
///
/// - SeeAlso: ``LaserPointerFeature``, ``VoiceTypingFeature``
@Reducer
public struct TrackpadFeature {
    // MARK: - State

    /// 트랙패드 기능의 현재 상태.
    @ObservableState
    public struct State: Equatable {
        /// 현재 입력 모드 (트랙패드 또는 레이저 포인터)
        public var mode: InputMode = .trackpad

        /// 터치 진행 중 여부
        public var isTouching: Bool = false

        /// 마지막 터치 위치 (델타 계산용)
        public var lastTouchPosition: CGPoint = .zero

        /// 마우스 이동 감도 (1.0 = 기본값)
        public var sensitivity: Double = 1.0

        /// 스크롤 감도 (1.0 = 기본값)
        public var scrollSensitivity: Double = 1.0

        /// 자연 스크롤 활성화 여부 (true = macOS 기본 방향)
        public var isNaturalScrolling: Bool = true

        /// 탭으로 클릭 활성화 여부
        public var isTapToClick: Bool = true

        /// 레이저 포인터 하위 상태
        public var laserPointer: LaserPointerFeature.State = .init()

        /// 음성 타이핑 하위 상태
        public var voiceTyping: VoiceTypingFeature.State = .init()

        // MARK: Power Saving Mode

        /// 배터리 절약 모드 활성화 여부
        public var isInPowerSavingMode: Bool = false

        /// 모션 업데이트 빈도 감소 활성화 여부
        public var reducedMotionUpdateRate: Bool = true

        /// 누적된 X축 이동량 (배치 전송용)
        public var accumulatedDeltaX: Float = 0

        /// 누적된 Y축 이동량 (배치 전송용)
        public var accumulatedDeltaY: Float = 0

        /// 스로틀 카운터 (3회마다 전송)
        public var throttleCounter: Int = 0

        public init() {}
    }

    // MARK: - InputMode

    /// 트랙패드 입력 모드.
    public enum InputMode: String, CaseIterable, Sendable {
        /// 일반 트랙패드 모드 - 터치 제스처로 마우스 제어
        case trackpad

        /// 레이저 포인터 모드 - 자이로스코프로 커서 제어
        case laser

        /// 모드의 지역화된 제목
        public var title: String {
            switch self {
            case .trackpad: return String(localized: "mode.trackpad")
            case .laser: return String(localized: "mode.laser")
            }
        }
    }

    // MARK: - Action

    /// 트랙패드 기능에서 발생하는 액션.
    public enum Action: Equatable, Sendable {
        // MARK: Mode

        /// 입력 모드 변경
        case modeChanged(InputMode)

        // MARK: Touch Events

        /// 터치 시작
        case touchBegan(CGPoint)

        /// 터치 이동 (마우스 이동 전송)
        case touchMoved(CGPoint)

        /// 터치 종료
        case touchEnded

        // MARK: Gestures

        /// 싱글 탭 (좌클릭)
        case tapped

        /// 더블 탭 (더블클릭)
        case doubleTapped

        /// 두 손가락 탭 (우클릭)
        case twoFingerTapped

        /// 두 손가락 스크롤
        case scrolled(deltaX: CGFloat, deltaY: CGFloat)

        /// 핀치 제스처 (확대/축소)
        case pinched(scale: CGFloat, phase: Pinch.Phase)

        // MARK: Click Buttons

        /// 좌클릭 버튼 누름
        case leftClickPressed

        /// 좌클릭 버튼 뗌
        case leftClickReleased

        /// 우클릭 버튼 누름
        case rightClickPressed

        /// 우클릭 버튼 뗌
        case rightClickReleased

        // MARK: Quick Actions

        /// Mission Control 실행 (Control + ↑)
        case missionControlPressed

        // MARK: Child Features

        /// 음성 타이핑 액션
        case voiceTyping(VoiceTypingFeature.Action)

        /// 레이저 포인터 액션
        case laserPointer(LaserPointerFeature.Action)

        // MARK: Settings

        /// 트랙패드 설정 업데이트
        case updateSettings(
            sensitivity: Double,
            scrollSensitivity: Double,
            isNaturalScrolling: Bool,
            isTapToClick: Bool
        )

        /// 배터리 절약 모드 상태 업데이트
        case updatePowerSavingMode(isInPowerSavingMode: Bool, reducedMotionUpdateRate: Bool)
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Scope(state: \.laserPointer, action: \.laserPointer) {
            LaserPointerFeature()
        }

        Scope(state: \.voiceTyping, action: \.voiceTyping) {
            VoiceTypingFeature()
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

                // 배터리 절약 모드에서 전송 주기 감소 (3번에 1번만 전송)
                if state.isInPowerSavingMode && state.reducedMotionUpdateRate {
                    state.accumulatedDeltaX += deltaX
                    state.accumulatedDeltaY += deltaY
                    state.throttleCounter += 1

                    if state.throttleCounter >= 3 {
                        let accX = state.accumulatedDeltaX
                        let accY = state.accumulatedDeltaY
                        state.accumulatedDeltaX = 0
                        state.accumulatedDeltaY = 0
                        state.throttleCounter = 0

                        return .run { _ in
                            await client.sendMouseMove(accX, accY)
                        }
                    }
                    return .none
                }

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

            case .pinched(let scale, let phase):
                return .run { _ in
                    await client.sendPinch(Float(scale), phase)
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

            case .updatePowerSavingMode(let isInPowerSavingMode, let reducedMotionUpdateRate):
                state.isInPowerSavingMode = isInPowerSavingMode
                state.reducedMotionUpdateRate = reducedMotionUpdateRate
                // 절약 모드 해제 시 누적값 초기화
                if !isInPowerSavingMode || !reducedMotionUpdateRate {
                    state.accumulatedDeltaX = 0
                    state.accumulatedDeltaY = 0
                    state.throttleCounter = 0
                }
                // 레이저 포인터에도 전달
                return .send(.laserPointer(.updatePowerSavingMode(isInPowerSavingMode && reducedMotionUpdateRate)))

            case .laserPointer:
                return .none

            case .voiceTyping:
                return .none
            }
        }
    }
}
