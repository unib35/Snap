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
/// - Note: `@unchecked Sendable` - 동기 잠금으로 읽기와 갱신 전체를 직렬화함
public final class TrustedDevicesManager: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = TrustedDevicesManager()

    // MARK: - Private Properties

    private let persistence: PersistenceManager
    private let trustedDevicesKey: String
    private let lock = NSRecursiveLock()

    // MARK: - Initialization

    /// - Parameter storageKey: 목록을 저장할 키. iOS는 페어링한 Mac 목록을 따로 저장합니다.
    public init(
        persistence: PersistenceManager = UserDefaultsPersistence.shared,
        storageKey: String = "com.snap.trustedDevices"
    ) {
        self.persistence = persistence
        self.trustedDevicesKey = storageKey
    }

    // MARK: - Public Methods

    /// 신뢰된 디바이스 목록 조회
    public var trustedDevices: [TrustedDevice] {
        lock.withLock {
            loadTrustedDevices()
        }
    }

    /// 디바이스가 신뢰되었는지 확인
    public func isTrusted(deviceID: String) -> Bool {
        lock.withLock {
            loadTrustedDevices().contains { $0.deviceID == deviceID }
        }
    }

    /// 신뢰된 디바이스 추가
    public func addTrustedDevice(_ device: TrustedDevice) {
        lock.withLock {
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

    /// 연결에 성공한 기기를 기록합니다.
    ///
    /// 처음 보는 기기면 지금 시각으로 추가하고, 이미 있으면 이름만 갱신해 페어링 날짜를 유지합니다.
    public func recordConnection(deviceID: String, deviceName: String) {
        lock.withLock {
            var devices = self.loadTrustedDevices()
            if let index = devices.firstIndex(where: { $0.deviceID == deviceID }) {
                guard devices[index].deviceName != deviceName else { return }
                devices[index].deviceName = deviceName
            } else {
                devices.append(TrustedDevice(deviceID: deviceID, deviceName: deviceName))
            }
            self.saveTrustedDevices(devices)
        }
    }

    /// 신뢰된 디바이스 제거
    public func removeTrustedDevice(deviceID: String) {
        lock.withLock {
            var devices = self.loadTrustedDevices()
            devices.removeAll { $0.deviceID == deviceID }
            self.saveTrustedDevices(devices)
        }
    }

    /// 모든 신뢰된 디바이스 제거
    public func removeAllTrustedDevices() {
        lock.withLock {
            saveTrustedDevices([])
        }
    }

    /// 디바이스 이름으로 조회
    public func deviceName(for deviceID: String) -> String? {
        lock.withLock {
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
