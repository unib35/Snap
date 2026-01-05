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
        public var lastError: ConnectionError?
        public var latency: TimeInterval = 0
        public var signalStrength: SignalStrength = .unknown

        // Pairing
        public var isPairingRequired: Bool = false
        public var pairingServerName: String = ""
        public var pairingPinCode: String = ""

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

        // App List
        case appListReceived([AppInfo])
        case focusApp(bundleID: String, pid: UInt32)

        // Now Playing
        case nowPlayingInfoReceived(NowPlayingInfo)

        // Pairing
        case pairingPinCodeChanged(String)
        case submitPairingPin
        case cancelPairing

        // Error
        case errorOccurred(ConnectionError)
        case clearError
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    private enum CancelID {
        case discovery
        case connection
    }

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
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

                case .error(let message):
                    state.lastError = .discoveryFailed(message)
                }
                return .none

            case .connect(let device):
                state.status = .connecting(device)
                state.lastError = nil

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

            case .disconnect:
                state.status = .disconnected
                state.connectedDevice = nil
                state.latency = 0
                state.signalStrength = .unknown
                return .merge(
                    .cancel(id: CancelID.connection),
                    .run { _ in await connectionClient.disconnect() }
                )

            case .connectionEvent(let event):
                switch event {
                case .connected(let serverName):
                    state.isPairingRequired = false
                    state.pairingPinCode = ""
                    if case .connecting(var device) = state.status {
                        device.name = serverName
                        state.status = .connected(device)
                        state.connectedDevice = device
                    }

                case .disconnected(let errorMessage):
                    state.status = .disconnected
                    state.connectedDevice = nil
                    state.isPairingRequired = false
                    state.pairingPinCode = ""
                    if let message = errorMessage {
                        state.lastError = .connectionLost(message)
                    }

                case .packet(let packetEvent):
                    switch packetEvent {
                    case .appList(let apps):
                        return .send(.appListReceived(apps))
                    case .nowPlayingInfo(let info):
                        return .send(.nowPlayingInfoReceived(info))
                    case .error(let message):
                        state.lastError = .serverError(message)
                    }

                case .error(let message):
                    state.lastError = .connectionFailed(message)
                    if case .connecting = state.status {
                        state.status = .disconnected
                    }

                case .pairingRequired(let serverName):
                    state.isPairingRequired = true
                    state.pairingServerName = serverName
                    state.pairingPinCode = ""

                case .pairingResult(let success, let message):
                    if success {
                        state.isPairingRequired = false
                        state.pairingPinCode = ""
                        // 연결은 서버가 handshake 응답 후 처리됨
                    } else {
                        state.lastError = .pairingFailed(message)
                        state.pairingPinCode = ""
                    }
                }
                return .none

            case .appListReceived:
                // Handled by parent feature
                return .none

            case .nowPlayingInfoReceived:
                // Handled by parent feature
                return .none

            case .focusApp(let bundleID, let pid):
                return .run { _ in
                    await connectionClient.sendAppFocus(bundleID, pid)
                }

            case .pairingPinCodeChanged(let pin):
                // 4자리 숫자만 허용
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
