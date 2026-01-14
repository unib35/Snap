import Foundation
import OSLog

private let logger = Logger(subsystem: "com.snap.shared", category: "PacketHeader")

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

    /// 버전 불일치 여부 (하위 호환성을 위해 처리는 계속하지만 경고 로깅)
    public let hasVersionMismatch: Bool

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
        self.hasVersionMismatch = false
    }

    /// 바이트 배열에서 헤더 파싱
    /// - Parameter data: 헤더 데이터
    /// - Note: 버전이 다르더라도 파싱을 시도하며, 버전 불일치 시 경고 로깅
    public init?(data: Data) {
        guard data.count >= NetworkConstants.packetHeaderSize else {
            return nil
        }

        // loadUnaligned를 사용하여 정렬되지 않은 메모리에서도 안전하게 읽기
        let magic = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 0, as: UInt16.self) }
        guard magic == NetworkConstants.packetMagic else {
            return nil
        }

        let version = data[2]

        // 버전 불일치 시 경고 로깅하고 처리 계속 (하위 호환성)
        if version != NetworkConstants.protocolVersion {
            logger.warning(
                """
                Protocol version mismatch - received: \(version), \
                expected: \(NetworkConstants.protocolVersion). \
                Attempting to process packet anyway.
                """
            )
        }

        guard let type = MessageType(rawValue: data[3]) else {
            return nil
        }

        let timestamp = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 4, as: UInt64.self) }
        let payloadLength = data.withUnsafeBytes { $0.loadUnaligned(fromByteOffset: 12, as: UInt32.self) }

        self.magic = magic
        self.version = version
        self.type = type
        self.timestamp = timestamp
        self.payloadLength = payloadLength
        self.hasVersionMismatch = version != NetworkConstants.protocolVersion
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

    /// 헤더 유효성 검사 (매직 넘버만 확인, 버전은 하위 호환성을 위해 무시)
    public var isValid: Bool {
        magic == NetworkConstants.packetMagic
    }

    /// 버전이 정확히 일치하는지 확인
    public var isExactVersionMatch: Bool {
        version == NetworkConstants.protocolVersion
    }
}
