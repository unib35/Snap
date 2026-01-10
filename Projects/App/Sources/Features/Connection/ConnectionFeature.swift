import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct ConnectionFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var status: ConnectionStatus = .disconnected
        public var discoveredDevices: IdentifiedArrayOf<Device> = []
        public var connectedDevice: Device?
        public var lastError: AppError?
        public var latency: TimeInterval = 0
        public var signalStrength: SignalStrength = .unknown

        // Pairing
        public var isPairingRequired: Bool = false
        public var pairingServerName: String = ""
        public var pairingPinCode: String = ""

        // Reconnection
        public var isAutoReconnectEnabled: Bool = true
        public var lastConnectedDevice: Device?
        public var reconnectAttempt: Int = 0
        public var networkInterface: NetworkInterface = .other

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        // Discovery
        case startDiscovery
        case stopDiscovery
        case discoveryEvent(DiscoveryEvent)

        // Connection
        case connect(Device)
        case disconnect
        case connectionEvent(ConnectionEvent)

        // Reconnection
        case attemptReconnect
        case cancelReconnect
        case reconnectDelayCompleted

        // Network Monitoring
        case startNetworkMonitoring
        case stopNetworkMonitoring
        case networkStatusChanged(NetworkStatusEvent)

        // App Lifecycle
        case appDidBecomeActive
        case appWillResignActive

        // App List
        case appListReceived([AppInfo])
        case focusApp(bundleID: String, pid: UInt32)

        // Now Playing
        case nowPlayingInfoReceived(NowPlayingInfo)

        // Pairing
        case pairingPinCodeChanged(String)
        case submitPairingPin
        case cancelPairing

        // Settings
        case setAutoReconnect(Bool)

        // Error
        case errorOccurred(AppError)
        case clearError
    }

    @Dependency(\.connectionClient) var connectionClient
    @Dependency(\.networkMonitorClient) var networkMonitorClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    private enum CancelID {
        case discovery
        case connection
        case reconnect
        case networkMonitor
    }

    // MARK: - Reconnection Configuration

    /// 최대 재시도 횟수
    private static let maxReconnectAttempts = 5

    /// 기본 재연결 지연 시간 (초)
    private static let baseReconnectDelay: Double = 1.0

    /// 최대 재연결 지연 시간 (초)
    private static let maxReconnectDelay: Double = 30.0

    /// Exponential backoff 지연 시간 계산
    private func reconnectDelay(for attempt: Int) -> Duration {
        let delay = min(
            Self.baseReconnectDelay * pow(2.0, Double(attempt)),
            Self.maxReconnectDelay
        )
        return .seconds(delay)
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            // MARK: - Discovery

            case .startDiscovery:
                guard state.status == .disconnected else { return .none }
                state.status = .discovering
                state.discoveredDevices.removeAll()

                return .run { send in
                    for await event in await connectionClient.startDiscovery() {
                        await send(.discoveryEvent(event))
                    }
                }
                .cancellable(id: CancelID.discovery)

            case .stopDiscovery:
                state.status = .disconnected
                return .merge(
                    .cancel(id: CancelID.discovery),
                    .run { _ in await connectionClient.stopDiscovery() }
                )

            case .discoveryEvent(let event):
                switch event {
                case .deviceFound(let discovered):
                    let device = Device(
                        id: discovered.id,
                        name: discovered.name,
                        host: discovered.host,
                        port: discovered.port
                    )
                    state.discoveredDevices.updateOrAppend(device)

                case .deviceLost(let name):
                    state.discoveredDevices.removeAll { $0.name == name }

                case .error:
                    state.lastError = .connection(.discoveryFailed)
                }
                return .none

            // MARK: - Connection

            case .connect(let device):
                state.status = .connecting(device)
                state.lastError = nil
                state.reconnectAttempt = 0
                state.lastConnectedDevice = device

                return .merge(
                    .cancel(id: CancelID.reconnect),
                    .run { send in
                        do {
                            for try await event in try await connectionClient.connect(device.host, device.port) {
                                await send(.connectionEvent(event))
                            }
                        } catch {
                            await send(.connectionEvent(.error(error.localizedDescription)))
                        }
                    }
                    .cancellable(id: CancelID.connection)
                )

            case .disconnect:
                state.status = .disconnected
                state.connectedDevice = nil
                state.lastConnectedDevice = nil
                state.latency = 0
                state.signalStrength = .unknown
                state.reconnectAttempt = 0
                return .merge(
                    .cancel(id: CancelID.connection),
                    .cancel(id: CancelID.reconnect),
                    .run { _ in await connectionClient.disconnect() }
                )

            case .connectionEvent(let event):
                switch event {
                case .connected(let serverName):
                    state.isPairingRequired = false
                    state.pairingPinCode = ""
                    state.reconnectAttempt = 0
                    if case .connecting(var device) = state.status {
                        device.name = serverName
                        state.status = .connected(device)
                        state.connectedDevice = device
                        state.lastConnectedDevice = device
                    } else if case .reconnecting(var device, _) = state.status {
                        device.name = serverName
                        state.status = .connected(device)
                        state.connectedDevice = device
                        state.lastConnectedDevice = device
                    }

                case .disconnected(let errorMessage):
                    let previousDevice = state.connectedDevice ?? state.lastConnectedDevice
                    state.connectedDevice = nil
                    state.isPairingRequired = false
                    state.pairingPinCode = ""

                    if errorMessage != nil {
                        state.lastError = .connection(.connectionLost)
                    }

                    // 자동 재연결 시도
                    if state.isAutoReconnectEnabled,
                       let device = previousDevice,
                       state.reconnectAttempt < Self.maxReconnectAttempts {
                        state.reconnectAttempt += 1
                        state.status = .reconnecting(device, attempt: state.reconnectAttempt)
                        return .send(.attemptReconnect)
                    } else {
                        state.status = .disconnected
                        state.reconnectAttempt = 0
                    }

                case .packet(let packetEvent):
                    switch packetEvent {
                    case .appList(let apps):
                        return .send(.appListReceived(apps))
                    case .nowPlayingInfo(let info):
                        return .send(.nowPlayingInfoReceived(info))
                    case .error(let message):
                        state.lastError = .connection(.serverError(message))
                    }

                case .error:
                    state.lastError = .connection(.connectionFailed)

                    // 연결 중 에러 발생 시 재연결 시도
                    if case .connecting(let device) = state.status {
                        if state.isAutoReconnectEnabled,
                           state.reconnectAttempt < Self.maxReconnectAttempts {
                            state.reconnectAttempt += 1
                            state.status = .reconnecting(device, attempt: state.reconnectAttempt)
                            return .send(.attemptReconnect)
                        } else {
                            state.status = .disconnected
                            state.reconnectAttempt = 0
                        }
                    } else if case .reconnecting(let device, _) = state.status {
                        if state.reconnectAttempt < Self.maxReconnectAttempts {
                            state.reconnectAttempt += 1
                            state.status = .reconnecting(device, attempt: state.reconnectAttempt)
                            return .send(.attemptReconnect)
                        } else {
                            state.status = .disconnected
                            state.reconnectAttempt = 0
                        }
                    }

                case .pairingRequired(let serverName):
                    state.isPairingRequired = true
                    state.pairingServerName = serverName
                    state.pairingPinCode = ""
                    state.reconnectAttempt = 0

                case .pairingResult(let success, _):
                    if success {
                        state.isPairingRequired = false
                        state.pairingPinCode = ""
                    } else {
                        state.lastError = .connection(.pairingFailed)
                        state.pairingPinCode = ""
                    }
                }
                return .none

            // MARK: - Reconnection

            case .attemptReconnect:
                guard case .reconnecting(_, let attempt) = state.status else {
                    return .none
                }

                let delay = reconnectDelay(for: attempt - 1)

                return .run { send in
                    try await clock.sleep(for: delay)
                    await send(.reconnectDelayCompleted)
                }
                .cancellable(id: CancelID.reconnect)

            case .cancelReconnect:
                state.status = .disconnected
                state.reconnectAttempt = 0
                return .merge(
                    .cancel(id: CancelID.reconnect),
                    .cancel(id: CancelID.connection)
                )

            case .reconnectDelayCompleted:
                guard case .reconnecting(let device, _) = state.status else {
                    return .none
                }

                return .run { send in
                    do {
                        for try await event in try await connectionClient.connect(device.host, device.port) {
                            await send(.connectionEvent(event))
                        }
                    } catch {
                        await send(.connectionEvent(.error(error.localizedDescription)))
                    }
                }
                .cancellable(id: CancelID.connection)

            // MARK: - Network Monitoring

            case .startNetworkMonitoring:
                return .run { send in
                    for await event in await networkMonitorClient.startMonitoring() {
                        await send(.networkStatusChanged(event))
                    }
                }
                .cancellable(id: CancelID.networkMonitor)

            case .stopNetworkMonitoring:
                networkMonitorClient.stopMonitoring()
                return .cancel(id: CancelID.networkMonitor)

            case .networkStatusChanged(let event):
                switch event {
                case .connected(let interface):
                    let previousInterface = state.networkInterface
                    state.networkInterface = interface

                    // 네트워크 인터페이스가 변경되었고, 이전에 연결된 디바이스가 있으면 재연결 시도
                    if previousInterface != interface,
                       state.status == .disconnected,
                       state.isAutoReconnectEnabled,
                       let device = state.lastConnectedDevice {
                        state.reconnectAttempt = 0
                        return .send(.connect(device))
                    }

                case .disconnected:
                    state.networkInterface = .other
                }
                return .none

            // MARK: - App Lifecycle

            case .appDidBecomeActive:
                // 포그라운드 전환 시 연결이 끊겼으면 재연결 시도
                if state.status == .disconnected,
                   state.isAutoReconnectEnabled,
                   let device = state.lastConnectedDevice {
                    state.reconnectAttempt = 0
                    return .send(.connect(device))
                }
                return .none

            case .appWillResignActive:
                // 백그라운드 전환 시 처리 (필요시)
                return .none

            // MARK: - App List & Now Playing

            case .appListReceived:
                return .none

            case .nowPlayingInfoReceived:
                return .none

            case .focusApp(let bundleID, let pid):
                return .run { _ in
                    await connectionClient.sendAppFocus(bundleID, pid)
                }

            // MARK: - Pairing

            case .pairingPinCodeChanged(let pin):
                let filtered = String(pin.filter { $0.isNumber }.prefix(4))
                state.pairingPinCode = filtered
                return .none

            case .submitPairingPin:
                guard state.pairingPinCode.count == 4 else { return .none }
                let pinCode = state.pairingPinCode
                return .run { _ in
                    await connectionClient.sendPairingResponse(pinCode)
                }

            case .cancelPairing:
                state.isPairingRequired = false
                state.pairingPinCode = ""
                return .run { _ in
                    await connectionClient.disconnect()
                }

            // MARK: - Settings

            case .setAutoReconnect(let enabled):
                state.isAutoReconnectEnabled = enabled
                if !enabled {
                    // 자동 재연결 비활성화 시 진행 중인 재연결 취소
                    if case .reconnecting = state.status {
                        state.status = .disconnected
                        state.reconnectAttempt = 0
                        return .merge(
                            .cancel(id: CancelID.reconnect),
                            .cancel(id: CancelID.connection)
                        )
                    }
                }
                return .none

            // MARK: - Error

            case .errorOccurred(let error):
                state.lastError = error
                return .none

            case .clearError:
                state.lastError = nil
                return .none
            }
        }
    }
}
