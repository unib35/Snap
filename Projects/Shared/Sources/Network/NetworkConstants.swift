import Foundation

/// 네트워크 관련 상수 정의
public enum NetworkConstants {
    /// TCP 제어 채널 포트
    public static let tcpPort: UInt16 = 51_234

    /// UDP 데이터 채널 포트
    public static let udpPort: UInt16 = 51_235

    /// Bonjour 서비스 타입 (TCP)
    public static let bonjourServiceTypeTCP = "_snap._tcp."

    /// Bonjour 서비스 타입 (UDP)
    public static let bonjourServiceTypeUDP = "_snap._udp."

    /// Bonjour 도메인
    public static let bonjourDomain = "local."

    /// 패킷 매직 넘버 ("SN" = 0x534E)
    public static let packetMagic: UInt16 = 0x534E

    /// 프로토콜 버전
    public static let protocolVersion: UInt8 = 0x01

    /// TCP Heartbeat 간격 (초)
    public static let tcpHeartbeatInterval: TimeInterval = 5.0

    /// UDP Heartbeat 간격 (초)
    public static let udpHeartbeatInterval: TimeInterval = 1.0

    /// 연결 타임아웃 (초)
    public static let connectionTimeout: TimeInterval = 15.0

    /// 최대 패킷 크기 (bytes)
    public static let maxPacketSize: Int = 65_536

    /// 패킷 헤더 크기 (bytes)
    public static let packetHeaderSize: Int = 16
}
