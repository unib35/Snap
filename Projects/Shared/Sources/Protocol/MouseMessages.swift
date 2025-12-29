import Foundation

// MARK: - MouseMove

/// 마우스 이동 (상대 좌표)
public struct MouseMove: Codable, Sendable, Equatable {
    public var deltaX: Float
    public var deltaY: Float

    public init(deltaX: Float = 0, deltaY: Float = 0) {
        self.deltaX = deltaX
        self.deltaY = deltaY
    }
}

// MARK: - MouseClick

/// 마우스 클릭
public struct MouseClick: Codable, Sendable, Equatable {
    public enum Button: Int, Codable, Sendable, CaseIterable {
        case left = 0
        case right = 1
        case middle = 2
    }

    public enum Action: Int, Codable, Sendable, CaseIterable {
        case down = 0
        case up = 1
        case click = 2
        case double = 3
    }

    public var button: Button
    public var action: Action

    public init(button: Button = .left, action: Action = .click) {
        self.button = button
        self.action = action
    }
}

// MARK: - Scroll

/// 스크롤
public struct Scroll: Codable, Sendable, Equatable {
    public var deltaX: Float
    public var deltaY: Float
    public var isInertia: Bool

    public init(deltaX: Float = 0, deltaY: Float = 0, isInertia: Bool = false) {
        self.deltaX = deltaX
        self.deltaY = deltaY
        self.isInertia = isInertia
    }
}

// MARK: - GyroData

/// 자이로스코프 데이터 (Laser Pointer용)
public struct GyroData: Codable, Sendable, Equatable {
    public var rotationRate: Vector3
    public var attitude: Vector3
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
