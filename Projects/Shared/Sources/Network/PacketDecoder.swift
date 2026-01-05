import Foundation

/// 디코딩 에러
public enum PacketDecodingError: Error, Sendable {
    case invalidHeader
    case invalidMagic
    case unsupportedVersion
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
    case ack(Ack, header: PacketHeader)
    case error(SnapError, header: PacketHeader)

    /// 메시지 타입
    public var messageType: MessageType {
        switch self {
        case .mouseMove: return .mouseMove
        case .mouseClick: return .mouseClick
        case .scroll: return .scroll
        case .gyroData: return .gyroData
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
    public static func decode(_ data: Data) throws -> DecodedPacket {
        // 헤더 파싱
        guard let header = PacketHeader(data: data) else {
            throw PacketDecodingError.invalidHeader
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
}
