import Foundation
import OSLog

private let logger = Logger(subsystem: "com.snap.shared", category: "PacketDecoder")

// MARK: - PacketDecodingError

/// 패킷 디코딩 중 발생할 수 있는 에러.
///
/// - SeeAlso: ``PacketDecoder``
public enum PacketDecodingError: Error, Sendable {
    /// 패킷 헤더가 유효하지 않음 (크기 부족 또는 형식 오류)
    case invalidHeader

    /// 매직 넘버가 일치하지 않음 (Snap 프로토콜이 아님)
    case invalidMagic

    /// 지원하지 않는 프로토콜 버전
    /// - Parameters:
    ///   - received: 수신된 버전
    ///   - expected: 예상 버전
    case unsupportedVersion(received: UInt8, expected: UInt8)

    /// 알 수 없는 메시지 타입
    case unknownMessageType

    /// 페이로드 데이터가 헤더에 명시된 길이보다 짧음
    case payloadTooShort

    /// JSON 디코딩 실패
    /// - Parameter error: 원본 디코딩 에러
    case decodingFailed(Error)
}

// MARK: - DecodedPacket

/// 디코딩된 Snap 프로토콜 패킷.
///
/// 수신된 네트워크 데이터를 디코딩한 결과로, 메시지 타입에 따라 연관된 데이터와 헤더를 포함합니다.
///
/// ## 메시지 카테고리
/// - **UDP 메시지**: 마우스 이동, 스크롤, 자이로 데이터 등 (저지연, 손실 허용)
/// - **TCP 메시지**: 키보드 입력, 미디어 컨트롤 등 (신뢰성 보장)
/// - **시스템 메시지**: 핸드셰이크, 하트비트, 페어링 등
///
/// ## 사용 예제
/// ```swift
/// let packet = try PacketDecoder.decode(data)
/// switch packet {
/// case .mouseMove(let move, _):
///     handleMouseMove(move.deltaX, move.deltaY)
/// case .keyEvent(let event, _):
///     handleKeyEvent(event)
/// default:
///     break
/// }
/// ```
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
    case systemCommand(SystemCommand, header: PacketHeader)
    case shortsCommand(ShortsCommand, header: PacketHeader)
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
        case .systemCommand: return .systemCommand
        case .shortsCommand: return .shortsCommand
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
             .systemCommand(_, let header),
             .shortsCommand(_, let header),
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

// MARK: - PacketDecoder

/// Snap 프로토콜 패킷을 디코딩하는 유틸리티.
///
/// `PacketDecoder`는 네트워크에서 수신한 바이너리 데이터를 파싱하여
/// 타입 안전한 Swift 객체로 변환합니다.
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
/// // 전체 패킷 디코딩
/// do {
///     let packet = try PacketDecoder.decode(receivedData)
///     print("수신된 메시지 타입: \(packet.messageType)")
/// } catch PacketDecodingError.invalidHeader {
///     print("잘못된 헤더")
/// } catch PacketDecodingError.payloadTooShort {
///     print("불완전한 패킷")
/// }
///
/// // 헤더만 파싱 (스트리밍 수신 시)
/// if let header = PacketDecoder.parseHeader(partialData) {
///     let totalLength = NetworkConstants.packetHeaderSize + Int(header.payloadLength)
///     // totalLength만큼 데이터가 수신될 때까지 대기
/// }
/// ```
///
/// - Note: 프로토콜 버전이 다르더라도 하위 호환성을 위해 디코딩을 시도합니다.
/// - SeeAlso: ``PacketEncoder``, ``DecodedPacket``, ``PacketHeader``
public enum PacketDecoder {
    private static let decoder = JSONDecoder()

    /// 바이너리 데이터에서 패킷을 디코딩합니다.
    ///
    /// - Parameter data: 수신된 패킷 데이터 (헤더 + 페이로드)
    /// - Returns: 디코딩된 패킷
    /// - Throws: ``PacketDecodingError``
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
            case .systemCommand:
                let message = try decoder.decode(SystemCommand.self, from: payload)
                return .systemCommand(message, header: header)
            case .shortsCommand:
                let message = try decoder.decode(ShortsCommand.self, from: payload)
                return .shortsCommand(message, header: header)
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
