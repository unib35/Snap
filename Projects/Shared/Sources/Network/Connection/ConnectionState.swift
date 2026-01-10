import Foundation

/// 연결 상태
public enum ConnectionState: Sendable, Equatable {
    case disconnected
    case connecting
    case connected
    case disconnecting
}

/// 연결 타임아웃 에러
public struct ConnectionTimeoutError: Error, LocalizedError, Sendable {
    public let timeout: TimeInterval

    public init(timeout: TimeInterval = NetworkConstants.connectionTimeout) {
        self.timeout = timeout
    }

    public var errorDescription: String? {
        "연결 시간이 초과되었습니다 (\(Int(timeout))초)"
    }
}

/// 연결 정보
public struct ConnectionInfo: Sendable, Equatable {
    public let deviceName: String
    public let deviceID: String
    public let host: String
    public let tcpPort: UInt16
    public let udpPort: UInt16

    public init(
        deviceName: String,
        deviceID: String,
        host: String,
        tcpPort: UInt16 = NetworkConstants.tcpPort,
        udpPort: UInt16 = NetworkConstants.udpPort
    ) {
        self.deviceName = deviceName
        self.deviceID = deviceID
        self.host = host
        self.tcpPort = tcpPort
        self.udpPort = udpPort
    }
}
