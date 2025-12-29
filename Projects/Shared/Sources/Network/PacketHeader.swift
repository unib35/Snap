import Foundation

/// 패킷 헤더 구조체
///
/// ```
/// +--------+--------+--------+--------+
/// |  Magic (2B)     | Version| Type   |
/// +--------+--------+--------+--------+
/// |          Timestamp (8B)           |
/// +--------+--------+--------+--------+
/// |          Payload Length (4B)      |
/// +--------+--------+--------+--------+
/// ```
public struct PacketHeader: Sendable, Equatable {
    /// 매직 넘버 (0x534E = "SN")
    public let magic: UInt16

    /// 프로토콜 버전
    public let version: UInt8

    /// 메시지 타입
    public let type: MessageType

    /// 타임스탬프 (마이크로초)
    public let timestamp: UInt64

    /// 페이로드 길이
    public let payloadLength: UInt32

    // MARK: - Initialization

    public init(
        type: MessageType,
        payloadLength: UInt32,
        timestamp: UInt64 = UInt64(Date().timeIntervalSince1970 * 1_000_000)
    ) {
        self.magic = NetworkConstants.packetMagic
        self.version = NetworkConstants.protocolVersion
        self.type = type
        self.timestamp = timestamp
        self.payloadLength = payloadLength
    }

    /// 바이트 배열에서 헤더 파싱
    public init?(data: Data) {
        guard data.count >= NetworkConstants.packetHeaderSize else {
            return nil
        }

        let magic = data.withUnsafeBytes { $0.load(fromByteOffset: 0, as: UInt16.self) }
        guard magic == NetworkConstants.packetMagic else {
            return nil
        }

        let version = data[2]
        guard version == NetworkConstants.protocolVersion else {
            return nil
        }

        guard let type = MessageType(rawValue: data[3]) else {
            return nil
        }

        let timestamp = data.withUnsafeBytes { $0.load(fromByteOffset: 4, as: UInt64.self) }
        let payloadLength = data.withUnsafeBytes { $0.load(fromByteOffset: 12, as: UInt32.self) }

        self.magic = magic
        self.version = version
        self.type = type
        self.timestamp = timestamp
        self.payloadLength = payloadLength
    }

    // MARK: - Serialization

    /// 헤더를 바이트 배열로 변환
    public func toData() -> Data {
        var data = Data(capacity: NetworkConstants.packetHeaderSize)

        // Magic (2 bytes, Little Endian)
        withUnsafeBytes(of: magic.littleEndian) { data.append(contentsOf: $0) }

        // Version (1 byte)
        data.append(version)

        // Type (1 byte)
        data.append(type.rawValue)

        // Timestamp (8 bytes, Little Endian)
        withUnsafeBytes(of: timestamp.littleEndian) { data.append(contentsOf: $0) }

        // Payload Length (4 bytes, Little Endian)
        withUnsafeBytes(of: payloadLength.littleEndian) { data.append(contentsOf: $0) }

        return data
    }

    // MARK: - Validation

    /// 헤더 유효성 검사
    public var isValid: Bool {
        magic == NetworkConstants.packetMagic &&
        version == NetworkConstants.protocolVersion
    }
}
