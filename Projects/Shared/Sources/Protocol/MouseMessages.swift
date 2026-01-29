import Foundation

// MARK: - MouseMove

/// 마우스 커서 이동 메시지.
///
/// 상대 좌표(델타)를 사용하여 커서 이동량을 전달합니다.
/// UDP로 전송되며 손실이 발생해도 다음 프레임에서 보정됩니다.
///
/// ## 사용 예제
/// ```swift
/// let move = MouseMove(deltaX: 10.5, deltaY: -5.2)
/// let packet = try PacketEncoder.encode(move)
/// ```
///
/// - Note: 전송 전 배치 처리되어 네트워크 효율을 높입니다.
public struct MouseMove: Codable, Sendable, Equatable {
    /// X축 이동량 (픽셀 단위, 양수: 오른쪽)
    public var deltaX: Float

    /// Y축 이동량 (픽셀 단위, 양수: 아래)
    public var deltaY: Float

    public init(deltaX: Float = 0, deltaY: Float = 0) {
        self.deltaX = deltaX
        self.deltaY = deltaY
    }
}

// MARK: - MouseClick

/// 마우스 클릭 메시지.
///
/// 버튼 종류와 클릭 동작을 지정합니다.
/// TCP로 전송되어 클릭이 반드시 전달됨을 보장합니다.
///
/// ## 사용 예제
/// ```swift
/// // 좌클릭
/// let click = MouseClick(button: .left, action: .click)
///
/// // 드래그 시작
/// let dragStart = MouseClick(button: .left, action: .down)
///
/// // 우클릭 (컨텍스트 메뉴)
/// let rightClick = MouseClick(button: .right, action: .click)
/// ```
public struct MouseClick: Codable, Sendable, Equatable {
    /// 마우스 버튼 종류
    public enum Button: Int, Codable, Sendable, CaseIterable {
        /// 왼쪽 버튼 (주 버튼)
        case left = 0
        /// 오른쪽 버튼 (보조 버튼, 컨텍스트 메뉴)
        case right = 1
        /// 가운데 버튼 (휠 버튼)
        case middle = 2
    }

    /// 클릭 동작
    public enum Action: Int, Codable, Sendable, CaseIterable {
        /// 버튼 누름 (드래그 시작)
        case down = 0
        /// 버튼 뗌 (드래그 종료)
        case up = 1
        /// 클릭 (누름 + 뗌)
        case click = 2
        /// 더블클릭
        case double = 3
    }

    /// 클릭할 버튼
    public var button: Button

    /// 수행할 동작
    public var action: Action

    public init(button: Button = .left, action: Action = .click) {
        self.button = button
        self.action = action
    }
}

// MARK: - Scroll

/// 스크롤 메시지.
///
/// 두 손가락 드래그에 의한 스크롤 이동량을 전달합니다.
/// 관성 스크롤(isInertia)은 손가락을 뗀 후에도 계속되는 스크롤입니다.
///
/// ## 사용 예제
/// ```swift
/// // 일반 스크롤
/// let scroll = Scroll(deltaX: 0, deltaY: 50, isInertia: false)
///
/// // 관성 스크롤
/// let inertia = Scroll(deltaX: 0, deltaY: 20, isInertia: true)
/// ```
public struct Scroll: Codable, Sendable, Equatable {
    /// X축 스크롤량 (양수: 오른쪽)
    public var deltaX: Float

    /// Y축 스크롤량 (양수: 아래, 자연 스크롤 기준)
    public var deltaY: Float

    /// 관성 스크롤 여부
    public var isInertia: Bool

    public init(deltaX: Float = 0, deltaY: Float = 0, isInertia: Bool = false) {
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.isInertia = isInertia
    }
}

// MARK: - Pinch

/// 핀치 제스처 메시지 (확대/축소).
///
/// 두 손가락 핀치 제스처의 스케일 변화를 전달합니다.
/// 1.0보다 크면 확대, 작으면 축소입니다.
///
/// ## 사용 예제
/// ```swift
/// // 핀치 시작
/// let began = Pinch(scale: 1.0, phase: .began)
///
/// // 확대 중
/// let zooming = Pinch(scale: 1.2, phase: .changed)
///
/// // 핀치 종료
/// let ended = Pinch(scale: 1.5, phase: .ended)
/// ```
public struct Pinch: Codable, Sendable, Equatable {
    /// 스케일 값 (1.0 = 기준, > 1.0 = 확대, < 1.0 = 축소)
    public var scale: Float

    /// 제스처 단계
    public var phase: Phase

    /// 핀치 제스처 단계
    public enum Phase: Int, Codable, Sendable {
        /// 제스처 시작
        case began = 0
        /// 제스처 진행 중 (스케일 변화)
        case changed = 1
        /// 제스처 종료
        case ended = 2
    }

    public init(scale: Float = 1.0, phase: Phase = .changed) {
        self.scale = scale
        self.phase = phase
    }
}

// MARK: - GyroData

/// 자이로스코프 데이터 메시지 (레이저 포인터 모드용).
///
/// 디바이스의 회전 데이터를 전달하여 레이저 포인터처럼 커서를 제어합니다.
/// CoreMotion에서 제공하는 자이로스코프 데이터를 기반으로 합니다.
///
/// ## 사용 예제
/// ```swift
/// let gyro = GyroData(
///     rotationRate: Vector3(x: 0.1, y: -0.05, z: 0),
///     attitude: Vector3(x: 0, y: 0, z: 0),
///     sensitivity: 15.0
/// )
/// ```
///
/// - Note: UDP로 전송되며, 저전력 모드에서 샘플링 빈도가 감소합니다.
public struct GyroData: Codable, Sendable, Equatable {
    /// 회전 속도 (rad/s)
    public var rotationRate: Vector3

    /// 디바이스 자세 (Euler angles)
    public var attitude: Vector3

    /// 감도 배율 (1.0 = 기본)
    public var sensitivity: Float

    public init(
        rotationRate: Vector3 = Vector3(),
        attitude: Vector3 = Vector3(),
        sensitivity: Float = 1.0
    ) {
        self.rotationRate = rotationRate
        self.attitude = attitude
        self.sensitivity = sensitivity
    }
}
