import Foundation
import OSLog

private let logger = Logger(subsystem: "com.snap.shared", category: "PacketDecoder")

/// 디코딩 에러
public enum PacketDecodingError: Error, Sendable {
    case invalidHeader
    case invalidMagic
    case unsupportedVersion(received: UInt8, expected: UInt8)
    case unknownMessageType
    case payloadTooShort
    case decodingFailed(Error)
}

/// 디코딩된 패킷
public enum DecodedPacket: Sendable {
    // UDP Messages
    case mouseMove(MouseMove, header: PacketHeader)
    case mouseClick(MouseClick, header: PacketHeader)
    case scroll(Scroll, header: PacketHeader)
    case gyroData(GyroData, header: PacketHeader)
    case pinch(Pinch, header: PacketHeader)

    // TCP Messages
    case keyEvent(KeyEvent, header: PacketHeader)
    case keyCombo(KeyCombo, header: PacketHeader)
    case mediaControl(MediaControl, header: PacketHeader)
    case nowPlayingInfo(NowPlayingInfo, header: PacketHeader)
    case windowSnap(WindowSnap, header: PacketHeader)
    case appListRequest(AppListRequest, header: PacketHeader)
    case appListResponse(AppListResponse, header: PacketHeader)
    case appFocus(AppFocus, header: PacketHeader)
    case openURL(OpenURL, header: PacketHeader)
    case presentation(Presentation, header: PacketHeader)
    case voiceText(VoiceText, header: PacketHeader)
    case siriCommand(SiriCommand, header: PacketHeader)

    // System Messages
    case handshake(Handshake, header: PacketHeader)
    case heartbeat(Heartbeat, header: PacketHeader)
    case disconnect(Disconnect, header: PacketHeader)
    case pairingChallenge(PairingChallenge, header: PacketHeader)
    case pairingResponse(PairingResponse, header: PacketHeader)
    case pairingResult(PairingResult, header: PacketHeader)
    case ack(Ack, header: PacketHeader)
    case error(SnapError, header: PacketHeader)

    /// 메시지 타입
    public var messageType: MessageType {
        switch self {
        case .mouseMove: return .mouseMove
        case .mouseClick: return .mouseClick
        case .scroll: return .scroll
        case .gyroData: return .gyroData
        case .pinch: return .pinch
        case .keyEvent: return .keyEvent
        case .keyCombo: return .keyCombo
        case .mediaControl: return .mediaControl
        case .nowPlayingInfo: return .nowPlayingInfo
        case .windowSnap: return .windowSnap
        case .appListRequest: return .appListRequest
        case .appListResponse: return .appListResponse
        case .appFocus: return .appFocus
        case .openURL: return .openURL
        case .presentation: return .presentation
        case .voiceText: return .voiceText
        case .siriCommand: return .siriCommand
        case .handshake: return .handshake
        case .heartbeat: return .heartbeat
        case .disconnect: return .disconnect
        case .pairingChallenge: return .pairingChallenge
        case .pairingResponse: return .pairingResponse
        case .pairingResult: return .pairingResult
        case .ack: return .ack
        case .error: return .error
        }
    }

    /// 패킷 헤더
    public var header: PacketHeader {
        switch self {
        case .mouseMove(_, let header),
             .mouseClick(_, let header),
             .scroll(_, let header),
             .gyroData(_, let header),
             .pinch(_, let header),
             .keyEvent(_, let header),
             .keyCombo(_, let header),
             .mediaControl(_, let header),
             .nowPlayingInfo(_, let header),
             .windowSnap(_, let header),
             .appListRequest(_, let header),
             .appListResponse(_, let header),
             .appFocus(_, let header),
             .openURL(_, let header),
             .presentation(_, let header),
             .voiceText(_, let header),
             .siriCommand(_, let header),
             .handshake(_, let header),
             .heartbeat(_, let header),
             .disconnect(_, let header),
             .pairingChallenge(_, let header),
             .pairingResponse(_, let header),
             .pairingResult(_, let header),
             .ack(_, let header),
             .error(_, let header):
            return header
        }
    }
}

/// 패킷 디코더
public enum PacketDecoder {
    private static let decoder = JSONDecoder()

    /// 데이터에서 패킷 디코딩
    /// - Parameter data: 패킷 데이터
    /// - Returns: 디코딩된 패킷
    /// - Throws: PacketDecodingError
    /// - Note: 버전 불일치 시 경고 로깅 후 처리를 계속합니다 (하위 호환성)
    public static func decode(_ data: Data) throws -> DecodedPacket {
        // 헤더 파싱
        guard let header = PacketHeader(data: data) else {
            throw PacketDecodingError.invalidHeader
        }

        // 버전 불일치 경고 로깅 (처리는 계속)
        if header.hasVersionMismatch {
            logger.warning(
                """
                Decoding packet with version mismatch - \
                received: \(header.version), \
                expected: \(NetworkConstants.protocolVersion). \
                Message type: \(String(describing: header.type))
                """
            )
        }

        // 페이로드 추출
        let payloadStart = NetworkConstants.packetHeaderSize
        let payloadEnd = payloadStart + Int(header.payloadLength)

        guard data.count >= payloadEnd else {
            throw PacketDecodingError.payloadTooShort
        }

        let payload = Data(data[payloadStart..<payloadEnd])

        // 메시지 타입에 따라 디코딩
        do {
            switch header.type {
            // UDP Messages
            case .mouseMove:
                let message = try decoder.decode(MouseMove.self, from: payload)
                return .mouseMove(message, header: header)
            case .mouseClick:
                let message = try decoder.decode(MouseClick.self, from: payload)
                return .mouseClick(message, header: header)
            case .scroll:
                let message = try decoder.decode(Scroll.self, from: payload)
                return .scroll(message, header: header)
            case .gyroData:
                let message = try decoder.decode(GyroData.self, from: payload)
                return .gyroData(message, header: header)
            case .pinch:
                let message = try decoder.decode(Pinch.self, from: payload)
                return .pinch(message, header: header)

            // TCP Messages
            case .keyEvent:
                let message = try decoder.decode(KeyEvent.self, from: payload)
                return .keyEvent(message, header: header)
            case .keyCombo:
                let message = try decoder.decode(KeyCombo.self, from: payload)
                return .keyCombo(message, header: header)
            case .mediaControl:
                let message = try decoder.decode(MediaControl.self, from: payload)
                return .mediaControl(message, header: header)
            case .nowPlayingInfo:
                let message = try decoder.decode(NowPlayingInfo.self, from: payload)
                return .nowPlayingInfo(message, header: header)
            case .windowSnap:
                let message = try decoder.decode(WindowSnap.self, from: payload)
                return .windowSnap(message, header: header)
            case .appListRequest:
                let message = try decoder.decode(AppListRequest.self, from: payload)
                return .appListRequest(message, header: header)
            case .appListResponse:
                let message = try decoder.decode(AppListResponse.self, from: payload)
                return .appListResponse(message, header: header)
            case .appFocus:
                let message = try decoder.decode(AppFocus.self, from: payload)
                return .appFocus(message, header: header)
            case .openURL:
                let message = try decoder.decode(OpenURL.self, from: payload)
                return .openURL(message, header: header)
            case .presentation:
                let message = try decoder.decode(Presentation.self, from: payload)
                return .presentation(message, header: header)
            case .voiceText:
                let message = try decoder.decode(VoiceText.self, from: payload)
                return .voiceText(message, header: header)
            case .siriCommand:
                let message = try decoder.decode(SiriCommand.self, from: payload)
                return .siriCommand(message, header: header)

            // System Messages
            case .handshake:
                let message = try decoder.decode(Handshake.self, from: payload)
                return .handshake(message, header: header)
            case .heartbeat:
                let message = try decoder.decode(Heartbeat.self, from: payload)
                return .heartbeat(message, header: header)
            case .disconnect:
                let message = try decoder.decode(Disconnect.self, from: payload)
                return .disconnect(message, header: header)
            case .pairingChallenge:
                let message = try decoder.decode(PairingChallenge.self, from: payload)
                return .pairingChallenge(message, header: header)
            case .pairingResponse:
                let message = try decoder.decode(PairingResponse.self, from: payload)
                return .pairingResponse(message, header: header)
            case .pairingResult:
                let message = try decoder.decode(PairingResult.self, from: payload)
                return .pairingResult(message, header: header)
            case .ack:
                let message = try decoder.decode(Ack.self, from: payload)
                return .ack(message, header: header)
            case .error:
                let message = try decoder.decode(SnapError.self, from: payload)
                return .error(message, header: header)
            }
        } catch {
            throw PacketDecodingError.decodingFailed(error)
        }
    }

    /// 헤더만 파싱 (페이로드 길이 확인용)
    public static func parseHeader(_ data: Data) -> PacketHeader? {
        PacketHeader(data: data)
    }

    /// 버전 호환성 확인
    /// - Parameter version: 확인할 프로토콜 버전
    /// - Returns: 호환 가능 여부
    /// - Note: 현재 구현에서는 모든 버전을 허용하고 경고만 로깅합니다
    public static func isVersionCompatible(_ version: UInt8) -> Bool {
        if version != NetworkConstants.protocolVersion {
            logger.info(
                """
                Version compatibility check - \
                received: \(version), \
                current: \(NetworkConstants.protocolVersion). \
                Allowing for backward compatibility.
                """
            )
        }
        return true  // 하위 호환성을 위해 모든 버전 허용
    }
}
