import ComposableArchitecture
import Testing
@testable import App

// MARK: - Test Helpers

private let testDevice = Device(
    id: "test-device-id",
    name: "Test Mac",
    host: "192.168.1.100",
    port: 12_345
)

private let discoveredDevice = DiscoveredDevice(
    id: "test-device-id",
    name: "Test Mac",
    host: "192.168.1.100",
    port: 12_345
)

// MARK: - Discovery Tests

@Suite("Discovery 테스트")
struct DiscoveryTests {
    @Test("Discovery 시작 시 상태가 discovering으로 변경")
    func startDiscovery() async {
        let store = await TestStore(initialState: ConnectionFeature.State()) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.startDiscovery = { .finished }
            $0.connectionClient.stopDiscovery = {}
        }

        await store.send(.startDiscovery) {
            $0.status = .discovering
            $0.discoveredDevices.removeAll()
        }
    }

    @Test("이미 연결 중이면 Discovery 시작 무시")
    func startDiscoveryWhileConnected() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.startDiscovery)
        // 상태 변화 없음
    }

    @Test("디바이스 발견 시 목록에 추가")
    func deviceFound() async {
        var state = ConnectionFeature.State()
        state.status = .discovering

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.discoveryEvent(.deviceFound(discoveredDevice))) {
            $0.discoveredDevices.append(testDevice)
        }
    }

    @Test("동일 디바이스 발견 시 업데이트")
    func deviceFoundUpdate() async {
        var state = ConnectionFeature.State()
        state.status = .discovering
        state.discoveredDevices.append(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        let updatedDevice = DiscoveredDevice(
            id: "test-device-id",
            name: "Updated Mac",
            host: "192.168.1.100",
            port: 12_345
        )

        await store.send(.discoveryEvent(.deviceFound(updatedDevice))) {
            $0.discoveredDevices[id: "test-device-id"]?.name = "Updated Mac"
        }
    }

    @Test("디바이스 손실 시 목록에서 제거")
    func deviceLost() async {
        var state = ConnectionFeature.State()
        state.status = .discovering
        state.discoveredDevices.append(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.discoveryEvent(.deviceLost("Test Mac"))) {
            $0.discoveredDevices.removeAll()
        }
    }

    @Test("Discovery 에러 시 lastError 설정")
    func discoveryError() async {
        var state = ConnectionFeature.State()
        state.status = .discovering

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.discoveryEvent(.error("Network error"))) {
            $0.lastError = .connection(.discoveryFailed)
        }
    }

    @Test("Discovery 중지 시 상태가 disconnected로 변경")
    func stopDiscovery() async {
        var state = ConnectionFeature.State()
        state.status = .discovering

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.stopDiscovery = {}
        }

        await store.send(.stopDiscovery) {
            $0.status = .disconnected
        }
    }
}

// MARK: - Connection Tests

@Suite("Connection 테스트")
struct ConnectionTests {
    @Test("연결 시작 시 상태가 connecting으로 변경")
    func connect() async {
        let store = await TestStore(initialState: ConnectionFeature.State()) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.connect = { _, _ in .finished }
        }

        await store.send(.connect(testDevice)) {
            $0.status = .connecting(testDevice)
            $0.lastError = nil
            $0.reconnectAttempt = 0
            $0.lastConnectedDevice = testDevice
        }
    }

    @Test("연결 성공 시 상태가 connected로 변경")
    func connectionSuccess() async {
        var state = ConnectionFeature.State()
        state.status = .connecting(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.connected(serverName: "My Mac"))) {
            var updatedDevice = testDevice
            updatedDevice.name = "My Mac"
            $0.status = .connected(updatedDevice)
            $0.connectedDevice = updatedDevice
            $0.lastConnectedDevice = updatedDevice
            $0.isPairingRequired = false
            $0.pairingPinCode = ""
            $0.reconnectAttempt = 0
        }
    }

    @Test("수동 연결 해제 시 상태 초기화")
    func disconnect() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)
        state.connectedDevice = testDevice
        state.lastConnectedDevice = testDevice

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.disconnect = {}
        }

        await store.send(.disconnect) {
            $0.status = .disconnected
            $0.connectedDevice = nil
            $0.lastConnectedDevice = nil
            $0.latency = 0
            $0.signalStrength = .unknown
            $0.reconnectAttempt = 0
        }
    }

    @Test("연결 끊김 시 자동 재연결 시도")
    func autoReconnectOnDisconnect() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)
        state.connectedDevice = testDevice
        state.lastConnectedDevice = testDevice
        state.isAutoReconnectEnabled = true

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.connectionClient.connect = { _, _ in .finished }
        }

        await store.send(.connectionEvent(.disconnected(error: "Connection lost"))) {
            $0.connectedDevice = nil
            $0.lastError = .connection(.connectionLost)
            $0.reconnectAttempt = 1
            $0.status = .reconnecting(testDevice, attempt: 1)
        }

        await store.receive(.attemptReconnect)
        await store.receive(.reconnectDelayCompleted)
    }

    @Test("자동 재연결 비활성화 시 재연결 안함")
    func noAutoReconnect() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)
        state.connectedDevice = testDevice
        state.lastConnectedDevice = testDevice
        state.isAutoReconnectEnabled = false

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.disconnected(error: "Connection lost"))) {
            $0.connectedDevice = nil
            $0.lastError = .connection(.connectionLost)
            $0.status = .disconnected
            $0.reconnectAttempt = 0
        }
    }

    @Test("재연결 취소")
    func cancelReconnect() async {
        var state = ConnectionFeature.State()
        state.status = .reconnecting(testDevice, attempt: 2)
        state.reconnectAttempt = 2

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.cancelReconnect) {
            $0.status = .disconnected
            $0.reconnectAttempt = 0
        }
    }
}

// MARK: - Pairing Tests

@Suite("Pairing 테스트")
struct PairingTests {
    @Test("페어링 요청 수신")
    func pairingRequired() async {
        var state = ConnectionFeature.State()
        state.status = .connecting(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.pairingRequired(serverName: "My Mac"))) {
            $0.isPairingRequired = true
            $0.pairingServerName = "My Mac"
            $0.pairingPinCode = ""
            $0.reconnectAttempt = 0
        }
    }

    @Test("PIN 코드 입력 - 숫자만 허용")
    func pairingPinCodeChanged() async {
        var state = ConnectionFeature.State()
        state.isPairingRequired = true

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.pairingPinCodeChanged("12ab34")) {
            $0.pairingPinCode = "1234"
        }
    }

    @Test("PIN 코드 입력 - 4자리 제한")
    func pairingPinCodeMaxLength() async {
        var state = ConnectionFeature.State()
        state.isPairingRequired = true

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.pairingPinCodeChanged("123456")) {
            $0.pairingPinCode = "1234"
        }
    }

    @Test("PIN 코드 제출 - 4자리 미만이면 무시")
    func submitPairingPinInvalid() async {
        var state = ConnectionFeature.State()
        state.isPairingRequired = true
        state.pairingPinCode = "123"

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.submitPairingPin)
        // 아무 동작 없음
    }

    @Test("PIN 코드 제출 - 4자리면 전송")
    func submitPairingPinValid() async {
        var state = ConnectionFeature.State()
        state.isPairingRequired = true
        state.pairingPinCode = "1234"

        let sentPinCode = LockIsolated<String?>(nil)
        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.sendPairingResponse = { pin in
                sentPinCode.setValue(pin)
            }
        }

        await store.send(.submitPairingPin)
        #expect(sentPinCode.value == "1234")
    }

    @Test("페어링 성공")
    func pairingSuccess() async {
        var state = ConnectionFeature.State()
        state.status = .connecting(testDevice)
        state.isPairingRequired = true
        state.pairingPinCode = "1234"

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.pairingResult(success: true, message: "Success"))) {
            $0.isPairingRequired = false
            $0.pairingPinCode = ""
        }
    }

    @Test("페어링 실패")
    func pairingFailure() async {
        var state = ConnectionFeature.State()
        state.status = .connecting(testDevice)
        state.isPairingRequired = true
        state.pairingPinCode = "1234"

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.pairingResult(success: false, message: "Wrong PIN"))) {
            $0.lastError = .connection(.pairingFailed)
            $0.pairingPinCode = ""
        }
    }

    @Test("페어링 취소")
    func cancelPairing() async {
        var state = ConnectionFeature.State()
        state.status = .connecting(testDevice)
        state.isPairingRequired = true
        state.pairingPinCode = "12"

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.disconnect = {}
        }

        await store.send(.cancelPairing) {
            $0.isPairingRequired = false
            $0.pairingPinCode = ""
        }
    }
}

// MARK: - Error Handling Tests

@Suite("에러 핸들링 테스트")
struct ErrorHandlingTests {
    @Test("연결 에러 발생 시 재연결 시도")
    func connectionErrorWithRetry() async {
        var state = ConnectionFeature.State()
        state.status = .connecting(testDevice)
        state.isAutoReconnectEnabled = true

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.continuousClock = ImmediateClock()
            $0.connectionClient.connect = { _, _ in .finished }
        }

        await store.send(.connectionEvent(.error("Connection refused"))) {
            $0.lastError = .connection(.connectionFailed)
            $0.reconnectAttempt = 1
            $0.status = .reconnecting(testDevice, attempt: 1)
        }

        await store.receive(.attemptReconnect)
        await store.receive(.reconnectDelayCompleted)
    }

    @Test("최대 재시도 횟수 초과 시 연결 해제")
    func maxReconnectAttemptsExceeded() async {
        var state = ConnectionFeature.State()
        state.status = .reconnecting(testDevice, attempt: 5)
        state.reconnectAttempt = 5
        state.isAutoReconnectEnabled = true

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.error("Connection refused"))) {
            $0.lastError = .connection(.connectionFailed)
            $0.status = .disconnected
            $0.reconnectAttempt = 0
        }
    }

    @Test("에러 발생 액션")
    func errorOccurred() async {
        let store = await TestStore(initialState: ConnectionFeature.State()) {
            ConnectionFeature()
        }

        await store.send(.errorOccurred(.general("Test error"))) {
            $0.lastError = .general("Test error")
        }
    }

    @Test("에러 초기화")
    func clearError() async {
        var state = ConnectionFeature.State()
        state.lastError = .general("Test error")

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.clearError) {
            $0.lastError = nil
        }
    }

    @Test("서버 에러 패킷 수신")
    func serverErrorPacket() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.connectionEvent(.packet(.error("Server error")))) {
            $0.lastError = .connection(.serverError("Server error"))
        }
    }
}

// MARK: - Network Monitoring Tests

@Suite("네트워크 모니터링 테스트")
struct NetworkMonitoringTests {
    @Test("네트워크 연결 시 인터페이스 업데이트")
    func networkConnected() async {
        let store = await TestStore(initialState: ConnectionFeature.State()) {
            ConnectionFeature()
        }

        await store.send(.networkStatusChanged(.connected(.wifi))) {
            $0.networkInterface = .wifi
        }
    }

    @Test("네트워크 연결 해제 시 인터페이스 초기화")
    func networkDisconnected() async {
        var state = ConnectionFeature.State()
        state.networkInterface = .wifi

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.networkStatusChanged(.disconnected)) {
            $0.networkInterface = .other
        }
    }

    @Test("네트워크 인터페이스 변경 시 자동 재연결")
    func networkInterfaceChangeReconnect() async {
        var state = ConnectionFeature.State()
        state.status = .disconnected
        state.networkInterface = .cellular
        state.isAutoReconnectEnabled = true
        state.lastConnectedDevice = testDevice

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.connect = { _, _ in .finished }
        }

        await store.send(.networkStatusChanged(.connected(.wifi))) {
            $0.networkInterface = .wifi
            $0.reconnectAttempt = 0
        }

        await store.receive(.connect(testDevice)) {
            $0.status = .connecting(testDevice)
            $0.lastError = nil
            $0.lastConnectedDevice = testDevice
        }
    }
}

// MARK: - App Lifecycle Tests

@Suite("앱 라이프사이클 테스트")
struct AppLifecycleTests {
    @Test("앱 활성화 시 자동 재연결")
    func appDidBecomeActiveReconnect() async {
        var state = ConnectionFeature.State()
        state.status = .disconnected
        state.isAutoReconnectEnabled = true
        state.lastConnectedDevice = testDevice
        state.reconnectAttempt = 2 // 이전 재시도가 있었던 상태

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        } withDependencies: {
            $0.connectionClient.connect = { _, _ in .finished }
        }

        await store.send(.appDidBecomeActive) {
            $0.reconnectAttempt = 0
        }

        await store.receive(.connect(testDevice)) {
            $0.status = .connecting(testDevice)
            $0.lastError = nil
            $0.lastConnectedDevice = testDevice
        }
    }

    @Test("앱 활성화 - 이미 연결되어 있으면 무시")
    func appDidBecomeActiveAlreadyConnected() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)
        state.connectedDevice = testDevice

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.appDidBecomeActive)
        // 아무 동작 없음
    }

    @Test("앱 백그라운드 전환")
    func appWillResignActive() async {
        var state = ConnectionFeature.State()
        state.status = .connected(testDevice)

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.appWillResignActive)
        // 현재 아무 동작 없음 (필요시 확장)
    }
}

// MARK: - Settings Tests

@Suite("설정 테스트")
struct SettingsTests {
    @Test("자동 재연결 활성화")
    func enableAutoReconnect() async {
        var state = ConnectionFeature.State()
        state.isAutoReconnectEnabled = false

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.setAutoReconnect(true)) {
            $0.isAutoReconnectEnabled = true
        }
    }

    @Test("자동 재연결 비활성화 시 진행 중인 재연결 취소")
    func disableAutoReconnectCancelsReconnect() async {
        var state = ConnectionFeature.State()
        state.status = .reconnecting(testDevice, attempt: 2)
        state.reconnectAttempt = 2
        state.isAutoReconnectEnabled = true

        let store = await TestStore(initialState: state) {
            ConnectionFeature()
        }

        await store.send(.setAutoReconnect(false)) {
            $0.isAutoReconnectEnabled = false
            $0.status = .disconnected
            $0.reconnectAttempt = 0
        }
    }
}
