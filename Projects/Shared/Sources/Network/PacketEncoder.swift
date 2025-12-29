import Foundation

/// 패킷 인코더
public enum PacketEncoder {
    private static let encoder = JSONEncoder()

    /// 메시지를 패킷 데이터로 인코딩
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

    /// Presentation 인코딩
    public static func encode(_ message: Presentation) throws -> Data {
        try encode(message, type: .presentation)
    }

    /// VoiceText 인코딩
    public static func encode(_ message: VoiceText) throws -> Data {
        try encode(message, type: .voiceText)
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
