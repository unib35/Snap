import Foundation

/// 메시지 타입 정의
public enum MessageType: UInt8, Sendable {
    // MARK: - UDP 메시지 (0x00 ~ 0x1F)

    /// 마우스 이동 (상대 좌표)
    case mouseMove = 0x01
    /// 마우스 클릭
    case mouseClick = 0x02
    /// 스크롤 (2D)
    case scroll = 0x03
    /// 자이로스코프 데이터
    case gyroData = 0x04
    /// 핀치 줌 (확대/축소)
    case pinch = 0x05

    // MARK: - TCP 메시지 (0x20 ~ 0x7F)

    /// 키보드 입력
    case keyEvent = 0x20
    /// 단축키 조합
    case keyCombo = 0x21
    /// 미디어 제어
    case mediaControl = 0x30
    /// Now Playing 정보 (macOS → iOS)
    case nowPlayingInfo = 0x31
    /// 윈도우 스냅
    case windowSnap = 0x40
    /// 앱 목록 요청
    case appListRequest = 0x50
    /// 앱 목록 응답
    case appListResponse = 0x51
    /// 앱 포커스 전환
    case appFocus = 0x52
    /// URL 열기
    case openURL = 0x53
    /// 발표 제어
    case presentation = 0x60
    /// 음성 텍스트
    case voiceText = 0x70
    /// Siri 호출
    case siriCommand = 0x71

    // MARK: - 시스템 메시지 (0x80 ~ 0xFF)

    /// 연결 초기화
    case handshake = 0x80
    /// 연결 유지 확인
    case heartbeat = 0x81
    /// 연결 종료
    case disconnect = 0x82
    /// 페어링 챌린지 (macOS → iOS: PIN 입력 요청)
    case pairingChallenge = 0x83
    /// 페어링 응답 (iOS → macOS: PIN 입력 결과)
    case pairingResponse = 0x84
    /// 페어링 결과 (macOS → iOS: 성공/실패)
    case pairingResult = 0x85
    /// 응답 확인
    case ack = 0xFE
    /// 에러 응답
    case error = 0xFF

    // MARK: - Properties

    /// UDP 메시지 여부
    public var isUDP: Bool {
        rawValue < 0x20
    }

    /// TCP 메시지 여부
    public var isTCP: Bool {
        rawValue >= 0x20 && rawValue < 0x80
    }

    /// 시스템 메시지 여부
    public var isSystem: Bool {
        rawValue >= 0x80
    }
}
