import ComposableArchitecture
import Foundation

@Reducer
public struct ConnectionFeature: Sendable {
    @ObservableState
    public struct State: Equatable, Sendable {
        public var status: ConnectionStatus = .disconnected
        public var discoveredDevices: IdentifiedArrayOf<Device> = []
        public var lastError: ConnectionError?
        public var latency: TimeInterval = 0
        public var signalStrength: SignalStrength = .unknown

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        // Discovery
        case startDiscovery
        case stopDiscovery
        case deviceDiscovered(Device)
        case deviceLost(Device.ID)

        // Connection
        case connect(Device)
        case disconnect
        case connectionStatusChanged(ConnectionStatus)

        // Heartbeat
        case heartbeatTick
        case heartbeatReceived(latency: TimeInterval)
        case heartbeatTimeout

        // Error
        case errorOccurred(ConnectionError)
        case clearError
    }

    @Dependency(\.continuousClock) var clock

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .startDiscovery:
                guard state.status == .disconnected else { return .none }
                state.status = .discovering
                state.discoveredDevices.removeAll()
                // TODO: Implement actual discovery
                return .none

            case .stopDiscovery:
                state.status = .disconnected
                return .none

            case .deviceDiscovered(let device):
                state.discoveredDevices.updateOrAppend(device)
                return .none

            case .deviceLost(let deviceID):
                state.discoveredDevices.remove(id: deviceID)
                return .none

            case .connect(let device):
                state.status = .connecting(device)
                state.lastError = nil
                // TODO: Implement actual connection
                return .none

            case .disconnect:
                state.status = .disconnected
                state.latency = 0
                state.signalStrength = .unknown
                return .none

            case .connectionStatusChanged(let status):
                state.status = status
                return .none

            case .heartbeatTick:
                // TODO: Send heartbeat
                return .none

            case .heartbeatReceived(let latency):
                state.latency = latency
                state.signalStrength = SignalStrength(latency: latency)
                return .none

            case .heartbeatTimeout:
                if case .connected(let device) = state.status {
                    state.status = .reconnecting(device, attempt: 1)
                }
                return .none

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
