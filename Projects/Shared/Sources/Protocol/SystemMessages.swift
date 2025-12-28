import Foundation

// MARK: - Handshake

/// 핸드셰이크
public struct Handshake: Codable, Sendable, Equatable {
    public var deviceName: String
    public var deviceID: String
    public var protocolVersion: UInt32
    public var appVersion: String

    public init(
        deviceName: String = "",
        deviceID: String = "",
        protocolVersion: UInt32 = UInt32(NetworkConstants.protocolVersion),
        appVersion: String = ""
    ) {
        self.deviceName = deviceName
        self.deviceID = deviceID
        self.protocolVersion = protocolVersion
        self.appVersion = appVersion
    }
}

// MARK: - Heartbeat

/// 하트비트
public struct Heartbeat: Codable, Sendable, Equatable {
    public var timestamp: UInt64

    public init(timestamp: UInt64 = UInt64(Date().timeIntervalSince1970 * 1_000_000)) {
        self.timestamp = timestamp
    }
}

// MARK: - SnapError

/// 에러
public struct SnapError: Codable, Sendable, Equatable, Error {
    public enum Code: Int, Codable, Sendable, CaseIterable {
        case unknown = 0
        case invalidPacket = 1
        case unsupportedVersion = 2
        case permissionDenied = 3
        case internalError = 4
    }

    public var code: Code
    public var message: String

    public init(code: Code = .unknown, message: String = "") {
        self.code = code
        self.message = message
    }
}

// MARK: - Ack

/// ACK
public struct Ack: Codable, Sendable, Equatable {
    public var originalTimestamp: UInt64

    public init(originalTimestamp: UInt64 = 0) {
        self.originalTimestamp = originalTimestamp
    }
}

// MARK: - Disconnect

/// 연결 종료
public struct Disconnect: Codable, Sendable, Equatable {
    public init() {}
}
