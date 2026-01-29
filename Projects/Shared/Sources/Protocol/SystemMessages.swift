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

// MARK: - Pairing

/// 페어링 챌린지 (macOS → iOS)
public struct PairingChallenge: Codable, Sendable, Equatable {
    public var deviceName: String
    public var deviceID: String

    public init(deviceName: String = "", deviceID: String = "") {
        self.deviceName = deviceName
        self.deviceID = deviceID
    }
}

/// 페어링 응답 (iOS → macOS)
public struct PairingResponse: Codable, Sendable, Equatable {
    public var pinCode: String
    public var deviceName: String
    public var deviceID: String

    public init(pinCode: String = "", deviceName: String = "", deviceID: String = "") {
        self.pinCode = pinCode
        self.deviceName = deviceName
        self.deviceID = deviceID
    }
}

/// 페어링 결과 (macOS → iOS)
public struct PairingResult: Codable, Sendable, Equatable {
    public enum Status: Int, Codable, Sendable {
        case success = 0
        case invalidPin = 1
        case timeout = 2
        case rejected = 3
    }

    public var status: Status
    public var message: String

    public init(status: Status = .success, message: String = "") {
        self.status = status
        self.message = message
    }

    public var isSuccess: Bool {
        status == .success
    }
}

// MARK: - System Command

/// 시스템 명령 (iOS → macOS)
public struct SystemCommand: Codable, Sendable, Equatable {
    public enum Command: Int, Codable, Sendable, CaseIterable {
        case sleep = 0
        case lock = 1
        case logout = 2
        case restart = 3
        case shutdown = 4
    }

    public var command: Command

    public init(command: Command) {
        self.command = command
    }
}
