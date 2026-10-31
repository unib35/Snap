import Foundation
import os
import Shared

private let logger = Logger(subsystem: "com.snap.app", category: "SnapClient")

/// Snap 클라이언트 델리게이트
public protocol SnapClientDelegate: AnyObject {
    func clientDidConnect(_ client: SnapClient)
    func clientDidDisconnect(_ client: SnapClient, error: Error?)
    func client(_ client: SnapClient, didReceive packet: DecodedPacket)
    func client(_ client: SnapClient, didFailWithError error: Error)
    /// Mac의 일회성 QR 코드 확인 요청
    func client(_ client: SnapClient, didReceivePairingChallenge challenge: PairingChallenge)
    /// 페어링 결과 수신
    func client(_ client: SnapClient, didReceivePairingResult result: PairingResult)
    /// 하트비트 왕복 시간 측정 (초)
    func client(_ client: SnapClient, didMeasureLatency latency: TimeInterval)
}

/// Snap 클라이언트 (iOS)
///
/// - Note: `@unchecked Sendable` - 내부 lock/queue를 통해 모든 상태 접근이 직렬화되어 스레드 안전함
public final class SnapClient: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: SnapClientDelegate?

    private let lock = NSRecursiveLock()
    private var udpSessionKey: Data?
    private let credentialStore: any PairingCredentialStore
    private var credential: PairingCredential?
    private var certificateVerifier: PairingCertificateVerifier?
    private var verifiedPairingCertificate: Data?
    private var expectedServerID: String?
    private var pairingChallenge: PairingChallenge?
    private var tcpConnection: TCPConnection?
    private var udpSocket: UDPSocket?
    private var heartbeatManager: HeartbeatManager?

    private let deviceName: String
    private let deviceID: String

    private var connectedHost: String?

    public private(set) var isConnected: Bool = false
    public private(set) var serverDeviceName: String?

    /// 보안 연결 사용 여부 (TLS + AES-GCM)
    public let useSecureConnection = true

    // MARK: - Initialization

    public init(deviceName: String? = nil, credentialStore: any PairingCredentialStore = KeychainPairingCredentialStore.shared) {
        self.deviceName = deviceName ?? "iOS Device"
        self.deviceID = Self.getDeviceID()
        self.credentialStore = credentialStore
    }

    /// iOS 디바이스 이름으로 초기화 (MainActor에서 호출)
    @MainActor
    public static func withCurrentDeviceName() -> SnapClient {
        #if os(iOS)
        let name = UIDevice.current.name
        #else
        let name = "iOS Device"
        #endif
        return SnapClient(deviceName: name)
    }

    // MARK: - Public Methods

    /// 서버에 연결
    public func connect(to host: String, port: UInt16 = NetworkConstants.tcpPort, serverID: String) {
        lock.lock()
        defer { lock.unlock() }
        guard tcpConnection == nil else { return }

        guard !serverID.isEmpty else {
            delegate?.clientDidDisconnect(self, error: PairingSecurityError.missingCredentials)
            return
        }
        do {
            credential = try credentialStore.load(for: "client:" + serverID)
            if credential != nil && credential?.serverCertificate == nil {
                throw PairingSecurityError.missingCredentials
            }
        } catch {
            delegate?.clientDidDisconnect(self, error: error)
            return
        }
        expectedServerID = serverID
        connectedHost = host
        let verifier = PairingCertificateVerifier(pinnedCertificate: credential?.serverCertificate)
        certificateVerifier = verifier
        tcpConnection = TCPConnection(
            host: host,
            port: port,
            useTLS: true,
            tlsOptions: SecurityManager.shared.createClientTLSOptions(verifier: verifier)
        )
        tcpConnection?.delegate = self
        tcpConnection?.connect()
    }

    /// 연결 해제
    public func disconnect() {
        lock.lock()
        defer { lock.unlock() }
        guard tcpConnection != nil else { return }

        // 연결 종료 메시지 전송
        let disconnect = Disconnect()
        tcpConnection?.send(disconnect, type: .disconnect)

        cleanup()
        delegate?.clientDidDisconnect(self, error: nil)
    }

    /// 마우스 이동 전송 (UDP)
    public func sendMouseMove(deltaX: Float, deltaY: Float) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let move = MouseMove(deltaX: deltaX, deltaY: deltaY)
        udpSocket?.send(move, type: .mouseMove)
    }

    /// 마우스 버튼 상태 전환은 신뢰성 있는 TCP로 전송
    public func sendMouseClick(button: MouseClick.Button, action: MouseClick.Action) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let click = MouseClick(button: button, action: action)
        tcpConnection?.send(click, type: .mouseClick)
    }

    /// 스크롤 전송 (UDP)
    public func sendScroll(deltaX: Float, deltaY: Float, isInertia: Bool = false) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let scroll = Scroll(deltaX: deltaX, deltaY: deltaY, isInertia: isInertia)
        udpSocket?.send(scroll, type: .scroll)
    }

    /// 핀치 줌 전송 (UDP)
    public func sendPinch(scale: Float, phase: Pinch.Phase) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let pinch = Pinch(scale: scale, phase: phase)
        udpSocket?.send(pinch, type: .pinch)
    }

    /// 자이로 데이터 전송 (UDP)
    public func sendGyroData(_ gyroData: GyroData) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        udpSocket?.send(gyroData, type: .gyroData)
    }

    /// 키 이벤트 전송 (TCP)
    public func sendKeyEvent(keyCode: UInt32, action: KeyEvent.Action, modifiers: UInt32 = 0) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let keyEvent = KeyEvent(keyCode: keyCode, action: action, modifiers: modifiers)
        tcpConnection?.send(keyEvent, type: .keyEvent)
    }

    /// 키 조합 전송 (TCP)
    public func sendKeyCombo(keyCodes: [UInt32], modifiers: UInt32) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let combo = KeyCombo(keyCodes: keyCodes, modifiers: modifiers)
        tcpConnection?.send(combo, type: .keyCombo)
    }

    /// 미디어 컨트롤 전송 (TCP)
    public func sendMediaControl(command: MediaControl.Command, volume: Float = 0) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let control = MediaControl(command: command, volume: volume)
        tcpConnection?.send(control, type: .mediaControl)
    }

    /// 윈도우 스냅 전송 (TCP)
    public func sendWindowSnap(position: WindowSnap.Position) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let snap = WindowSnap(position: position)
        tcpConnection?.send(snap, type: .windowSnap)
    }

    /// 앱 목록 요청 (TCP)
    public func requestAppList() {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let request = AppListRequest()
        tcpConnection?.send(request, type: .appListRequest)
    }

    /// 앱 포커스 전송 (TCP)
    public func sendAppFocus(bundleID: String, pid: UInt32) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let focus = AppFocus(bundleID: bundleID, pid: pid)
        tcpConnection?.send(focus, type: .appFocus)
    }

    /// Siri 명령 전송 (TCP)
    public func sendSiriCommand(action: SiriCommand.Action, text: String = "") {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let command = SiriCommand(action: action, text: text)
        tcpConnection?.send(command, type: .siriCommand)
    }

    /// 음성 텍스트 전송 (TCP)
    public func sendVoiceText(text: String, isFinal: Bool) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let voiceText = VoiceText(text: text, isFinal: isFinal)
        tcpConnection?.send(voiceText, type: .voiceText)
    }

    /// URL 열기 전송 (TCP)
    public func sendOpenURL(url: String) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let openURL = OpenURL(url: url)
        tcpConnection?.send(openURL, type: .openURL)
    }

    /// 시스템 명령 전송 (TCP)
    public func sendSystemCommand(command: SystemCommand.Command) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let systemCommand = SystemCommand(command: command)
        tcpConnection?.send(systemCommand, type: .systemCommand)
    }

    /// 숏폼 리모컨 명령 전송 (TCP)
    public func sendShortsCommand(platform: ShortsCommand.Platform, action: ShortsCommand.Action) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let shortsCommand = ShortsCommand(platform: platform, action: action)
        tcpConnection?.send(shortsCommand, type: .shortsCommand)
    }

    /// 발표 명령 전송 (TCP)
    public func sendPresentation(command: Presentation.Command) {
        lock.lock()
        defer { lock.unlock() }
        guard isConnected else { return }

        let presentation = Presentation(command: command)
        tcpConnection?.send(presentation, type: .presentation)
    }

    /// 페어링 응답 전송 (TCP)
    /// Only an out-of-band code matching this TLS leaf and challenge can
    /// authorize sending the one-time pairing secret to a provisional peer.
    public func sendPairingCode(_ value: String) {
        lock.lock()
        defer { lock.unlock() }
        guard !isConnected, let challenge = pairingChallenge,
              let nonce = challenge.nonce, let serverID = expectedServerID,
              let certificate = certificateVerifier?.certificate else { return }
        do {
            let code = try PairingDisplayCode.decode(value)
            try code.validate(serverID: serverID, certificate: certificate, challenge: nonce)
            verifiedPairingCertificate = certificate
            let response = PairingResponse(
                pinCode: code.pin, deviceName: deviceName, deviceID: deviceID, nonce: nonce
            )
            tcpConnection?.send(response, type: .pairingResponse)
        } catch {
            delegate?.client(self, didReceivePairingResult: PairingResult(status: .rejected, message: error.localizedDescription))
        }
    }

    // MARK: - Private Methods

    private static func getDeviceID() -> String {
        let defaults = UserDefaults.standard
        if let savedID = defaults.string(forKey: "SnapDeviceID") {
            return savedID
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: "SnapDeviceID")
        return newID
    }

    private func cleanup() {
        heartbeatManager?.stop()
        heartbeatManager = nil

        let connection = tcpConnection
        tcpConnection = nil
        connection?.disconnect()
        udpSessionKey = nil
        credential = nil
        certificateVerifier = nil
        verifiedPairingCertificate = nil
        expectedServerID = nil
        pairingChallenge = nil

        udpSocket?.close()
        udpSocket = nil

        isConnected = false
        serverDeviceName = nil
        connectedHost = nil
    }

    private func sendHandshake() {
        let handshake = Handshake(
            deviceName: deviceName,
            deviceID: deviceID,
            protocolVersion: UInt32(NetworkConstants.protocolVersion),
            appVersion: "1.0.0",
            authenticationToken: credential?.token
        )
        tcpConnection?.send(handshake, type: .handshake)
    }

    private func setupUDPSocket() {
        guard let host = connectedHost else { return }

        // TLS로 교환한 세션 키로 UDP를 암호화
        udpSocket = UDPSocket(role: .client)
        udpSocket?.delegate = self
        udpSocket?.setSessionKey(udpSessionKey)
        udpSocket?.connect(to: host, port: NetworkConstants.udpPort)
    }

    private func setupHeartbeat() {
        heartbeatManager = HeartbeatManager(
            interval: HeartbeatManager.tcpInterval,
            timeout: HeartbeatManager.timeout
        )
        heartbeatManager?.delegate = self
        heartbeatManager?.start()
    }

    private func handleHandshakeResponse(_ handshake: Handshake) {
        guard !isConnected else { return }
        guard handshake.protocolVersion == NetworkConstants.protocolVersion,
              handshake.deviceID == expectedServerID,
              let serverID = expectedServerID,
              let key = handshake.udpSessionKey, key.count == 32,
              let token = handshake.authenticationToken, token.count == 32,
              let certificate = certificateVerifier?.certificate,
              certificate == credential?.serverCertificate || certificate == verifiedPairingCertificate else {
            cleanup()
            delegate?.clientDidDisconnect(self, error: PairingSecurityError.missingCredentials)
            return
        }
        do {
            let saved = PairingCredential(token: token, serverCertificate: certificate)
            try credentialStore.save(saved, for: "client:" + serverID)
            credential = saved
        } catch {
            cleanup()
            delegate?.clientDidDisconnect(self, error: error)
            return
        }
        udpSessionKey = key
        serverDeviceName = handshake.deviceName
        isConnected = true
        pairingChallenge = nil
        verifiedPairingCertificate = nil
        setupUDPSocket()
        setupHeartbeat()
        delegate?.clientDidConnect(self)
    }
}

// MARK: - TCPConnectionDelegate

extension SnapClient: TCPConnectionDelegate {
    public func tcpConnectionDidConnect(_ connection: TCPConnection) {
        lock.lock()
        defer { lock.unlock() }
        guard connection === tcpConnection else { return }
        // TCP 연결 완료 후 핸드셰이크 전송
        sendHandshake()
    }

    public func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?) {
        lock.lock()
        defer { lock.unlock() }
        guard connection === tcpConnection else { return }
        cleanup()
        delegate?.clientDidDisconnect(self, error: error)
    }

    public func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket) {
        lock.lock()
        defer { lock.unlock() }
        guard connection === tcpConnection else { return }
        heartbeatManager?.didReceiveMessage()

        switch packet {
        case .handshake(let handshake, _):
            handleHandshakeResponse(handshake)

        case .pairingChallenge(let challenge, _):
            guard !isConnected, challenge.deviceID == expectedServerID, challenge.nonce?.count == 32 else {
                cleanup()
                delegate?.clientDidDisconnect(self, error: PairingSecurityError.invalidCode)
                return
            }
            pairingChallenge = challenge
            delegate?.client(self, didReceivePairingChallenge: challenge)

        case .pairingResult(let result, _):
            guard !result.isSuccess || verifiedPairingCertificate != nil else { return }
            delegate?.client(self, didReceivePairingResult: result)

        case .heartbeat(let heartbeat, _):
            heartbeatManager?.didReceiveHeartbeat()
            // Ack 응답
            let ack = Ack(originalTimestamp: heartbeat.timestamp)
            connection.send(ack, type: .ack)

        case .ack(let ack, _):
            // 내가 보낸 하트비트의 타임스탬프가 그대로 돌아오므로 왕복 시간을 계산할 수 있음
            let now = HeartbeatManager.currentTimestamp()
            guard isConnected, ack.originalTimestamp > 0, now >= ack.originalTimestamp else { return }
            let latency = TimeInterval(now - ack.originalTimestamp) / 1_000_000
            delegate?.client(self, didMeasureLatency: latency)

        case .error(let snapError, _):
            delegate?.client(self, didFailWithError: snapError)

        case .disconnect:
            cleanup()
            delegate?.clientDidDisconnect(self, error: nil)

        default:
            guard isConnected else { return }
            delegate?.client(self, didReceive: packet)
        }
    }
}

// MARK: - UDPSocketDelegate

extension SnapClient: UDPSocketDelegate {
    public func udpSocketDidReady(_ socket: UDPSocket) {
        lock.lock()
        defer { lock.unlock() }
        guard socket === udpSocket else { return }
        logger.debug("UDP socket ready")
    }

    public func udpSocket(_ socket: UDPSocket, didReceive packet: DecodedPacket, from endpoint: NetworkEndpoint, sessionID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        guard socket === udpSocket, isConnected else { return }
        delegate?.client(self, didReceive: packet)
    }

    public func udpSocket(_ socket: UDPSocket, didFailWithError error: Error) {
        lock.lock()
        defer { lock.unlock() }
        guard socket === udpSocket else { return }
        delegate?.client(self, didFailWithError: error)
    }
}

// MARK: - HeartbeatManagerDelegate

extension SnapClient: HeartbeatManagerDelegate {
    public func heartbeatManagerDidTimeout(_ manager: HeartbeatManager) {
        lock.lock()
        defer { lock.unlock() }
        guard manager === heartbeatManager else { return }
        logger.warning("Heartbeat timeout")
        cleanup()
        delegate?.clientDidDisconnect(self, error: ConnectionError.timeout)
    }

    public func heartbeatManager(_ manager: HeartbeatManager, shouldSendHeartbeat: @escaping @Sendable () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard manager === heartbeatManager else { return }
        let heartbeat = HeartbeatManager.createHeartbeat()
        tcpConnection?.send(heartbeat, type: .heartbeat) { _ in
            shouldSendHeartbeat()
        }
    }
}

// MARK: - NetworkEndpoint Typealias

import Network
public typealias NetworkEndpoint = NWEndpoint

#if os(iOS)
import UIKit
#endif
