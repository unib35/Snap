import Foundation

// MARK: - PacketEncoder

/// Snap 프로토콜 메시지를 네트워크 패킷으로 인코딩하는 유틸리티.
///
/// `PacketEncoder`는 Codable 메시지를 Snap 프로토콜 형식의 바이너리 데이터로 변환합니다.
/// 인코딩된 패킷은 헤더와 페이로드로 구성됩니다.
///
/// ## 패킷 구조
/// ```
/// +----------------+------------------+
/// | Header (5B)    | Payload (N Bytes)|
/// +----------------+------------------+
/// | Type (1B)      |                  |
/// | Length (4B)    | JSON Encoded     |
/// +----------------+------------------+
/// ```
///
/// ## 사용 예제
/// ```swift
/// // 마우스 이동 패킷 생성
/// let mouseMove = MouseMove(deltaX: 10.5, deltaY: -5.2)
/// let packet = try PacketEncoder.encode(mouseMove)
///
/// // 범용 인코딩 (타입 명시)
/// let keyEvent = KeyEvent(keyCode: 36, action: .down, modifiers: 0)
/// let packet = try PacketEncoder.encode(keyEvent, type: .keyEvent)
/// ```
///
/// - Note: 페이로드는 JSON 형식으로 인코딩됩니다.
/// - SeeAlso: ``PacketDecoder``, ``PacketHeader``, ``MessageType``
public enum PacketEncoder {
    private static let encoder = JSONEncoder()

    /// 메시지를 패킷 데이터로 인코딩합니다.
    ///
    /// - Parameters:
    ///   - message: 인코딩할 Codable 메시지
    ///   - type: 메시지 타입 식별자
    /// - Returns: 헤더와 페이로드가 결합된 패킷 데이터
    /// - Throws: JSON 인코딩 실패 시 에러
    public static func encode<T: Codable & Sendable>(
        _ message: T,
        type: MessageType
    ) throws -> Data {
        let payload = try encoder.encode(message)
        let header = PacketHeader(type: type, payloadLength: UInt32(payload.count))

        var data = header.toData()
        data.append(payload)

        return data
    }

    // MARK: - Convenience Methods

    /// MouseMove 인코딩
    public static func encode(_ message: MouseMove) throws -> Data {
        try encode(message, type: .mouseMove)
    }

    /// MouseClick 인코딩
    public static func encode(_ message: MouseClick) throws -> Data {
        try encode(message, type: .mouseClick)
    }

    /// Scroll 인코딩
    public static func encode(_ message: Scroll) throws -> Data {
        try encode(message, type: .scroll)
    }

    /// GyroData 인코딩
    public static func encode(_ message: GyroData) throws -> Data {
        try encode(message, type: .gyroData)
    }

    /// KeyEvent 인코딩
    public static func encode(_ message: KeyEvent) throws -> Data {
        try encode(message, type: .keyEvent)
    }

    /// KeyCombo 인코딩
    public static func encode(_ message: KeyCombo) throws -> Data {
        try encode(message, type: .keyCombo)
    }

    /// MediaControl 인코딩
    public static func encode(_ message: MediaControl) throws -> Data {
        try encode(message, type: .mediaControl)
    }

    /// WindowSnap 인코딩
    public static func encode(_ message: WindowSnap) throws -> Data {
        try encode(message, type: .windowSnap)
    }

    /// AppListRequest 인코딩
    public static func encode(_ message: AppListRequest) throws -> Data {
        try encode(message, type: .appListRequest)
    }

    /// AppListResponse 인코딩
    public static func encode(_ message: AppListResponse) throws -> Data {
        try encode(message, type: .appListResponse)
    }

    /// AppFocus 인코딩
    public static func encode(_ message: AppFocus) throws -> Data {
        try encode(message, type: .appFocus)
    }

    /// OpenURL 인코딩
    public static func encode(_ message: OpenURL) throws -> Data {
        try encode(message, type: .openURL)
    }

    /// Presentation 인코딩
    public static func encode(_ message: Presentation) throws -> Data {
        try encode(message, type: .presentation)
    }

    /// VoiceText 인코딩
    public static func encode(_ message: VoiceText) throws -> Data {
        try encode(message, type: .voiceText)
    }

    /// SystemCommand 인코딩
    public static func encode(_ message: SystemCommand) throws -> Data {
        try encode(message, type: .systemCommand)
    }

    /// ShortsCommand 인코딩
    public static func encode(_ message: ShortsCommand) throws -> Data {
        try encode(message, type: .shortsCommand)
    }

    /// Handshake 인코딩
    public static func encode(_ message: Handshake) throws -> Data {
        try encode(message, type: .handshake)
    }

    /// Heartbeat 인코딩
    public static func encode(_ message: Heartbeat) throws -> Data {
        try encode(message, type: .heartbeat)
    }

    /// Disconnect 인코딩
    public static func encode(_ message: Disconnect) throws -> Data {
        try encode(message, type: .disconnect)
    }

    /// Ack 인코딩
    public static func encode(_ message: Ack) throws -> Data {
        try encode(message, type: .ack)
    }

    /// SnapError 인코딩
    public static func encode(_ message: SnapError) throws -> Data {
        try encode(message, type: .error)
    }
}
