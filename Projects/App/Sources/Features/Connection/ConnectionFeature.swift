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

        // Reconnection
        public var isAutoReconnectEnabled: Bool = true
        public var lastConnectedDevice: Device?
        public var reconnectAttempt: Int = 0
        public var networkInterface: NetworkInterface = .other

        // Saved Macs
        /// 페어링해 연결한 적 있는 Mac (이름, 페어링 날짜)
        public var savedDevices: [TrustedDevice] = []

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        // Discovery
        case startDiscovery
        case stopDiscovery
        case discoveryEvent(DiscoveryEvent)

        // Connection
        case connect(Device)
        case forgetAndPair(Device)
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
        case volumeStateReceived(VolumeState)

        // Pairing
        case pairingCodeScanned(String)
        case cancelPairing

        // Saved Macs
        case loadSavedDevices
        case savedDevicesLoaded([TrustedDevice])
        case forgetSavedDevice(id: String)

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

                return .merge(
                    .run { send in
                        for await event in await connectionClient.startDiscovery() {
                            await send(.discoveryEvent(event))
                        }
                    }
                    .cancellable(id: CancelID.discovery),
                    .send(.loadSavedDevices)
                )

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

                case .deviceLost(let deviceID):
                    state.discoveredDevices.remove(id: deviceID)

                case .error:
                    state.lastError = .connection(.discoveryFailed)
                }
                return .none

            // MARK: - Connection

            case .forgetAndPair(let device):
                state.status = .disconnected
                state.connectedDevice = nil
                state.lastConnectedDevice = nil
                state.reconnectAttempt = 0
                return .concatenate(
                    .merge(.cancel(id: CancelID.connection), .cancel(id: CancelID.reconnect)),
                    .run { send in
                        do {
                            try await connectionClient.forgetDevice(device.id)
                            await send(.connect(device))
                        } catch {
                            await send(.connectionEvent(.error(error.localizedDescription)))
                        }
                    }
                )

            case .connect(let device):
                state.status = .connecting(device)
                state.lastError = nil
                state.reconnectAttempt = 0
                state.lastConnectedDevice = device

                return .merge(
                    .cancel(id: CancelID.reconnect),
                    .run { send in
                        do {
                            for try await event in try await connectionClient.connect(device.host, device.port, device.id) {
                                await send(.connectionEvent(event))
                            }
                        } catch {
                            await send(.connectionEvent(.error(error.localizedDescription)))
                        }
                    }
                    .cancellable(id: CancelID.connection, cancelInFlight: true)
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
                    return .send(.loadSavedDevices)

                case .disconnected(let errorMessage):
                    let previousDevice = state.connectedDevice ?? state.lastConnectedDevice
                    state.connectedDevice = nil
                    state.isPairingRequired = false

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
                    case .volumeState(let volumeState):
                        return .send(.volumeStateReceived(volumeState))
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
                    state.reconnectAttempt = 0

                case .pairingResult(let success, _):
                    if success {
                        state.isPairingRequired = false
                    } else {
                        state.lastError = .connection(.pairingFailed)
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
                .cancellable(id: CancelID.reconnect, cancelInFlight: true)

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
                        for try await event in try await connectionClient.connect(device.host, device.port, device.id) {
                            await send(.connectionEvent(event))
                        }
                    } catch {
                        await send(.connectionEvent(.error(error.localizedDescription)))
                    }
                }
                .cancellable(id: CancelID.connection, cancelInFlight: true)

            // MARK: - Network Monitoring

            case .startNetworkMonitoring:
                return .run { send in
                    for await event in await networkMonitorClient.startMonitoring() {
                        await send(.networkStatusChanged(event))
                    }
                }
                .cancellable(id: CancelID.networkMonitor, cancelInFlight: true)

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

            case .nowPlayingInfoReceived, .volumeStateReceived:
                return .none

            case .focusApp(let bundleID, let pid):
                return .run { _ in
                    await connectionClient.sendAppFocus(bundleID, pid)
                }

            // MARK: - Pairing

            case .pairingCodeScanned(let code):
                guard state.isPairingRequired else { return .none }
                return .run { _ in await connectionClient.sendPairingResponse(code) }

            case .cancelPairing:
                state.isPairingRequired = false
                state.status = .disconnected
                state.connectedDevice = nil
                state.lastConnectedDevice = nil
                state.reconnectAttempt = 0
                return .merge(
                    .cancel(id: CancelID.connection),
                    .cancel(id: CancelID.reconnect),
                    .run { _ in await connectionClient.disconnect() }
                )

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

            // MARK: - Saved Macs

            case .loadSavedDevices:
                return .run { send in
                    await send(.savedDevicesLoaded(await connectionClient.savedDevices()))
                }

            case .savedDevicesLoaded(let devices):
                state.savedDevices = devices
                return .none

            case .forgetSavedDevice(let id):
                state.savedDevices.removeAll { $0.id == id }
                // 연결 중이거나 재연결하려던 Mac이면 끊고, 지운 Mac으로 자동 재연결하지 않는다.
                var cancelConnection: Effect<Action> = .none
                if state.connectedDevice?.id == id || state.lastConnectedDevice?.id == id {
                    state.status = .disconnected
                    state.connectedDevice = nil
                    state.lastConnectedDevice = nil
                    state.latency = 0
                    state.signalStrength = .unknown
                    state.reconnectAttempt = 0
                    cancelConnection = .merge(.cancel(id: CancelID.connection), .cancel(id: CancelID.reconnect))
                }
                return .concatenate(
                    cancelConnection,
                    .run { send in
                        do {
                            try await connectionClient.forgetDevice(id)
                        } catch {
                            await send(.errorOccurred(.general(error.localizedDescription)))
                        }
                        await send(.loadSavedDevices)
                    }
                )
            }
        }
    }
}
