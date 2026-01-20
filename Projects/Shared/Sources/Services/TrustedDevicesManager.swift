import Foundation

/// 신뢰된 디바이스 정보
public struct TrustedDevice: Codable, Sendable, Equatable, Identifiable {
    public var id: String { deviceID }
    public var deviceID: String
    public var deviceName: String
    public var pairedAt: Date

    public init(deviceID: String, deviceName: String, pairedAt: Date = Date()) {
        self.deviceID = deviceID
        self.deviceName = deviceName
        self.pairedAt = pairedAt
    }
}

/// 신뢰된 디바이스 관리자
///
/// - Note: `@unchecked Sendable` - 내부 DispatchQueue(`queue`)를 통해 barrier를 사용한 reader-writer 패턴으로 스레드 안전함
public final class TrustedDevicesManager: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = TrustedDevicesManager()

    // MARK: - Private Properties

    private let persistence: PersistenceManager
    private let trustedDevicesKey = "com.snap.trustedDevices"
    private let queue = DispatchQueue(label: "com.snap.trustedDevices", attributes: .concurrent)

    // MARK: - Initialization

    public init(persistence: PersistenceManager = UserDefaultsPersistence.shared) {
        self.persistence = persistence
    }

    // MARK: - Public Methods

    /// 신뢰된 디바이스 목록 조회
    public var trustedDevices: [TrustedDevice] {
        queue.sync {
            loadTrustedDevices()
        }
    }

    /// 디바이스가 신뢰되었는지 확인
    public func isTrusted(deviceID: String) -> Bool {
        queue.sync {
            loadTrustedDevices().contains { $0.deviceID == deviceID }
        }
    }

    /// 신뢰된 디바이스 추가
    public func addTrustedDevice(_ device: TrustedDevice) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            var devices = self.loadTrustedDevices()

            // 이미 존재하면 업데이트
            if let index = devices.firstIndex(where: { $0.deviceID == device.deviceID }) {
                devices[index] = device
            } else {
                devices.append(device)
            }

            self.saveTrustedDevices(devices)
        }
    }

    /// 신뢰된 디바이스 추가 (ID와 이름으로)
    public func addTrustedDevice(deviceID: String, deviceName: String) {
        let device = TrustedDevice(deviceID: deviceID, deviceName: deviceName)
        addTrustedDevice(device)
    }

    /// 신뢰된 디바이스 제거
    public func removeTrustedDevice(deviceID: String) {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            var devices = self.loadTrustedDevices()
            devices.removeAll { $0.deviceID == deviceID }
            self.saveTrustedDevices(devices)
        }
    }

    /// 모든 신뢰된 디바이스 제거
    public func removeAllTrustedDevices() {
        queue.async(flags: .barrier) { [weak self] in
            self?.saveTrustedDevices([])
        }
    }

    /// 디바이스 이름으로 조회
    public func deviceName(for deviceID: String) -> String? {
        queue.sync {
            loadTrustedDevices().first { $0.deviceID == deviceID }?.deviceName
        }
    }

    // MARK: - Private Methods

    private func loadTrustedDevices() -> [TrustedDevice] {
        persistence.load(forKey: trustedDevicesKey, default: [])
    }

    private func saveTrustedDevices(_ devices: [TrustedDevice]) {
        persistence.save(devices, forKey: trustedDevicesKey)
    }
}

// MARK: - PIN Code Generator

public enum PINCodeGenerator {
    /// 4자리 랜덤 PIN 코드 생성
    public static func generate() -> String {
        let pin = Int.random(in: 0...9999)
        return String(format: "%04d", pin)
    }

    /// PIN 코드 유효성 검사
    public static func isValid(_ pin: String) -> Bool {
        pin.count == 4 && pin.allSatisfy { $0.isNumber }
    }
}
