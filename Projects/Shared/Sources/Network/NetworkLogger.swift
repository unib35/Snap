import Foundation
import os

/// 네트워크 로깅 유틸리티
/// 구조화된 로깅과 카테고리별 필터링 지원
public enum NetworkLogger {
    // MARK: - Loggers

    /// TCP 관련 로깅
    public static let tcp = Logger(subsystem: subsystem, category: "Network.TCP")

    /// UDP 관련 로깅
    public static let udp = Logger(subsystem: subsystem, category: "Network.UDP")

    /// Bonjour 서비스 검색 로깅
    public static let bonjour = Logger(subsystem: subsystem, category: "Network.Bonjour")

    /// TLS/DTLS 보안 로깅
    public static let security = Logger(subsystem: subsystem, category: "Security.TLS")

    /// 일반 네트워크 로깅
    public static let general = Logger(subsystem: subsystem, category: "Network")

    // MARK: - Configuration

    private static let subsystem = "com.snap.network"

    // MARK: - Convenience Methods

    /// 연결 상태 변경 로깅
    public static func logConnectionStateChange(
        from oldState: String,
        to newState: String,
        host: String? = nil,
        port: UInt16? = nil
    ) {
        if let host, let port {
            tcp.info("Connection state: \(oldState) → \(newState) [\(host):\(port)]")
        } else {
            tcp.info("Connection state: \(oldState) → \(newState)")
        }
    }

    /// 패킷 전송 로깅
    public static func logPacketSent(
        type: String,
        size: Int,
        protocol: String = "TCP"
    ) {
        let logger = `protocol` == "UDP" ? udp : tcp
        logger.debug("Sent \(type) packet (\(size) bytes)")
    }

    /// 패킷 수신 로깅
    public static func logPacketReceived(
        type: String,
        size: Int,
        protocol: String = "TCP"
    ) {
        let logger = `protocol` == "UDP" ? udp : tcp
        logger.debug("Received \(type) packet (\(size) bytes)")
    }

    /// 패킷 전송 실패 로깅
    public static func logPacketSendFailed(
        type: String,
        error: Error,
        protocol: String = "TCP"
    ) {
        let logger = `protocol` == "UDP" ? udp : tcp
        logger.error("Failed to send \(type) packet: \(error.localizedDescription)")
    }

    /// 연결 에러 로깅
    public static func logConnectionError(_ error: Error, context: String? = nil) {
        if let context {
            tcp.error("Connection error [\(context)]: \(error.localizedDescription)")
        } else {
            tcp.error("Connection error: \(error.localizedDescription)")
        }
    }

    /// 타임아웃 로깅
    public static func logTimeout(type: String, duration: TimeInterval) {
        tcp.warning("\(type) timeout after \(String(format: "%.1f", duration)) seconds")
    }

    /// Bonjour 서비스 발견 로깅
    public static func logServiceDiscovered(name: String, host: String, port: UInt16) {
        bonjour.info("Discovered service: \(name) at \(host):\(port)")
    }

    /// Bonjour 서비스 소실 로깅
    public static func logServiceLost(name: String) {
        bonjour.info("Lost service: \(name)")
    }

    /// TLS 핸드셰이크 로깅
    public static func logTLSHandshake(success: Bool, host: String) {
        if success {
            security.info("TLS handshake successful with \(host)")
        } else {
            security.warning("TLS handshake failed with \(host)")
        }
    }

    /// 네트워크 인터페이스 변경 로깅
    public static func logNetworkInterfaceChange(from: String, to: String) {
        general.info("Network interface changed: \(from) → \(to)")
    }
}
