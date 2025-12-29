import Foundation

// MARK: - Point

/// 2D 좌표
public struct Point: Codable, Sendable, Equatable {
    public var x: Float
    public var y: Float

    public init(x: Float = 0, y: Float = 0) {
        self.x = x
        self.y = y
    }
}

// MARK: - Vector3

/// 3D 벡터 (자이로스코프용)
public struct Vector3: Codable, Sendable, Equatable {
    public var x: Float
    public var y: Float
    public var z: Float

    public init(x: Float = 0, y: Float = 0, z: Float = 0) {
        self.x = x
        self.y = y
        self.z = z
    }
}
