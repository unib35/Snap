import CoreMotion
import Foundation
import Shared

/// 모션 이벤트
public enum MotionEvent: Equatable, Sendable {
    case update(GyroData)
    case error(String)
}

/// CoreMotion 기반 모션 매니저
public final class MotionManager: @unchecked Sendable {
    // MARK: - Properties

    private let motionManager = CMMotionManager()
    private var referenceAttitude: CMAttitude?
    private var sensitivity: Float = 15.0

    private let updateInterval: TimeInterval = 1.0 / 60.0 // 60Hz

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// 모션 업데이트 시작
    public func startUpdates() -> AsyncStream<MotionEvent> {
        AsyncStream { continuation in
            guard motionManager.isDeviceMotionAvailable else {
                continuation.yield(.error("Device motion is not available"))
                continuation.finish()
                return
            }

            motionManager.deviceMotionUpdateInterval = updateInterval

            motionManager.startDeviceMotionUpdates(
                using: .xArbitraryZVertical,
                to: .main
            ) { [weak self] motion, error in
                guard let self = self else { return }

                if let error = error {
                    continuation.yield(.error(error.localizedDescription))
                    return
                }

                guard let motion = motion else { return }

                let gyroData = self.processMotion(motion)
                continuation.yield(.update(gyroData))
            }

            continuation.onTermination = { [weak self] _ in
                self?.stopUpdates()
            }
        }
    }

    /// 모션 업데이트 중지
    public func stopUpdates() {
        motionManager.stopDeviceMotionUpdates()
        referenceAttitude = nil
    }

    /// 기준점 캘리브레이션 (현재 위치를 기준으로 설정)
    public func calibrate() {
        referenceAttitude = motionManager.deviceMotion?.attitude.copy() as? CMAttitude
    }

    /// 감도 설정 (1.0 ~ 50.0)
    public func setSensitivity(_ value: Float) {
        sensitivity = max(1.0, min(50.0, value))
    }

    /// 현재 감도
    public var currentSensitivity: Float {
        sensitivity
    }

    /// Device motion 사용 가능 여부
    public var isAvailable: Bool {
        motionManager.isDeviceMotionAvailable
    }

    // MARK: - Private Methods

    private func processMotion(_ motion: CMDeviceMotion) -> GyroData {
        // 기준점 대비 상대 attitude 계산
        let attitude = motion.attitude

        if let reference = referenceAttitude {
            attitude.multiply(byInverseOf: reference)
        }

        // Rotation rate (rad/s)
        let rotationRate = Vector3(
            x: Float(motion.rotationRate.x),
            y: Float(motion.rotationRate.y),
            z: Float(motion.rotationRate.z)
        )

        // Attitude (pitch, roll, yaw in radians)
        let attitudeVector = Vector3(
            x: Float(attitude.pitch),
            y: Float(attitude.roll),
            z: Float(attitude.yaw)
        )

        return GyroData(
            rotationRate: rotationRate,
            attitude: attitudeVector,
            sensitivity: sensitivity
        )
    }
}
