import Foundation

/// 발견된 디바이스 정보
public struct Device: Equatable, Identifiable, Sendable {
    public var id: String
    public var name: String
    public let host: String
    public let port: UInt16

    public init(id: String, name: String, host: String, port: UInt16) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
    }
}

/// 연결 상태
public enum ConnectionStatus: Equatable, Sendable {
    case disconnected
    case discovering
    case connecting(Device)
    case connected(Device)
    case reconnecting(Device, attempt: Int)

    public var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    public var connectedDevice: Device? {
        switch self {
        case .connected(let device), .reconnecting(let device, _):
            return device
        default:
            return nil
        }
    }
}

/// 신호 강도
public enum SignalStrength: Equatable, Sendable {
    case unknown
    case weak      // > 100ms
    case moderate  // 50-100ms
    case strong    // < 50ms

    public init(latency: TimeInterval) {
        switch latency {
        case ..<0.05:
            self = .strong
        case 0.05..<0.1:
            self = .moderate
        default:
            self = .weak
        }
    }
}

/// 연결 에러
public enum ConnectionError: Error, Equatable, Sendable {
    case discoveryFailed(String)
    case connectionFailed(String)
    case connectionLost(String)
    case serverError(String)
    case timeout
    case disconnected
    case protocolError(String)
}
