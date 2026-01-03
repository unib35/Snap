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
}

/// Snap 클라이언트 (iOS)
public final class SnapClient: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: SnapClientDelegate?

    private var tcpConnection: TCPConnection?
    private var udpSocket: UDPSocket?
    private var heartbeatManager: HeartbeatManager?

    private let deviceName: String
    private let deviceID: String

    private var connectedHost: String?

    public private(set) var isConnected: Bool = false
    public private(set) var serverDeviceName: String?

    // MARK: - Initialization

    public init(deviceName: String? = nil) {
        self.deviceName = deviceName ?? "iOS Device"
        self.deviceID = Self.getDeviceID()
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
    public func connect(to host: String, port: UInt16 = NetworkConstants.tcpPort) {
        guard !isConnected else { return }

        connectedHost = host

        // TCP 연결
        tcpConnection = TCPConnection(host: host, port: port)
        tcpConnection?.delegate = self
        tcpConnection?.connect()
    }

    /// 연결 해제
    public func disconnect() {
        guard isConnected else { return }

        // 연결 종료 메시지 전송
        let disconnect = Disconnect()
        tcpConnection?.send(disconnect, type: .disconnect)

        cleanup()
        delegate?.clientDidDisconnect(self, error: nil)
    }

    /// 마우스 이동 전송 (UDP)
    public func sendMouseMove(deltaX: Float, deltaY: Float) {
        guard isConnected else { return }

        let move = MouseMove(deltaX: deltaX, deltaY: deltaY)
        udpSocket?.send(move, type: .mouseMove)
    }

    /// 마우스 클릭 전송 (UDP)
    public func sendMouseClick(button: MouseClick.Button, action: MouseClick.Action) {
        guard isConnected else { return }

        let click = MouseClick(button: button, action: action)
        udpSocket?.send(click, type: .mouseClick)
    }

    /// 스크롤 전송 (UDP)
    public func sendScroll(deltaX: Float, deltaY: Float, isInertia: Bool = false) {
        guard isConnected else { return }

        let scroll = Scroll(deltaX: deltaX, deltaY: deltaY, isInertia: isInertia)
        udpSocket?.send(scroll, type: .scroll)
    }

    /// 키 이벤트 전송 (TCP)
    public func sendKeyEvent(keyCode: UInt32, action: KeyEvent.Action, modifiers: UInt32 = 0) {
        guard isConnected else { return }

        let keyEvent = KeyEvent(keyCode: keyCode, action: action, modifiers: modifiers)
        tcpConnection?.send(keyEvent, type: .keyEvent)
    }

    /// 키 조합 전송 (TCP)
    public func sendKeyCombo(keyCodes: [UInt32], modifiers: UInt32) {
        guard isConnected else { return }

        let combo = KeyCombo(keyCodes: keyCodes, modifiers: modifiers)
        tcpConnection?.send(combo, type: .keyCombo)
    }

    /// 미디어 컨트롤 전송 (TCP)
    public func sendMediaControl(command: MediaControl.Command, volume: Float = 0) {
        guard isConnected else { return }

        let control = MediaControl(command: command, volume: volume)
        tcpConnection?.send(control, type: .mediaControl)
    }

    /// 윈도우 스냅 전송 (TCP)
    public func sendWindowSnap(position: WindowSnap.Position) {
        guard isConnected else { return }

        let snap = WindowSnap(position: position)
        tcpConnection?.send(snap, type: .windowSnap)
    }

    /// 앱 목록 요청 (TCP)
    public func requestAppList() {
        guard isConnected else { return }

        let request = AppListRequest()
        tcpConnection?.send(request, type: .appListRequest)
    }

    /// 앱 포커스 전송 (TCP)
    public func sendAppFocus(bundleID: String, pid: UInt32) {
        guard isConnected else { return }

        let focus = AppFocus(bundleID: bundleID, pid: pid)
        tcpConnection?.send(focus, type: .appFocus)
    }

    /// Siri 명령 전송 (TCP)
    public func sendSiriCommand(action: SiriCommand.Action, text: String = "") {
        guard isConnected else { return }

        let command = SiriCommand(action: action, text: text)
        tcpConnection?.send(command, type: .siriCommand)
    }

    /// 음성 텍스트 전송 (TCP)
    public func sendVoiceText(text: String, isFinal: Bool) {
        guard isConnected else { return }

        let voiceText = VoiceText(text: text, isFinal: isFinal)
        tcpConnection?.send(voiceText, type: .voiceText)
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

        tcpConnection?.disconnect()
        tcpConnection = nil

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
            appVersion: "1.0.0"
        )
        tcpConnection?.send(handshake, type: .handshake)
    }

    private func setupUDPSocket() {
        guard let host = connectedHost else { return }

        udpSocket = UDPSocket()
        udpSocket?.delegate = self
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
        serverDeviceName = handshake.deviceName
        isConnected = true

        // UDP 소켓 설정
        setupUDPSocket()

        // 하트비트 시작
        setupHeartbeat()

        delegate?.clientDidConnect(self)
    }
}

// MARK: - TCPConnectionDelegate

extension SnapClient: TCPConnectionDelegate {
    public func tcpConnectionDidConnect(_ connection: TCPConnection) {
        // TCP 연결 완료 후 핸드셰이크 전송
        sendHandshake()
    }

    public func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?) {
        cleanup()
        delegate?.clientDidDisconnect(self, error: error)
    }

    public func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket) {
        heartbeatManager?.didReceiveMessage()

        switch packet {
        case .handshake(let handshake, _):
            handleHandshakeResponse(handshake)

        case .heartbeat(let heartbeat, _):
            heartbeatManager?.didReceiveHeartbeat()
            // Ack 응답
            let ack = Ack(originalTimestamp: heartbeat.timestamp)
            connection.send(ack, type: .ack)

        case .ack:
            // 하트비트 Ack 수신
            break

        case .error(let snapError, _):
            delegate?.client(self, didFailWithError: snapError)

        case .disconnect:
            cleanup()
            delegate?.clientDidDisconnect(self, error: nil)

        default:
            // 다른 패킷은 델리게이트로 전달
            delegate?.client(self, didReceive: packet)
        }
    }
}

// MARK: - UDPSocketDelegate

extension SnapClient: UDPSocketDelegate {
    public func udpSocketDidReady(_ socket: UDPSocket) {
        logger.debug("UDP socket ready")
    }

    public func udpSocket(_ socket: UDPSocket, didReceive packet: DecodedPacket, from endpoint: NetworkEndpoint) {
        delegate?.client(self, didReceive: packet)
    }

    public func udpSocket(_ socket: UDPSocket, didFailWithError error: Error) {
        delegate?.client(self, didFailWithError: error)
    }
}

// MARK: - HeartbeatManagerDelegate

extension SnapClient: HeartbeatManagerDelegate {
    public func heartbeatManagerDidTimeout(_ manager: HeartbeatManager) {
        logger.warning("Heartbeat timeout")
        cleanup()
        delegate?.clientDidDisconnect(self, error: ConnectionError.timeout)
    }

    public func heartbeatManager(_ manager: HeartbeatManager, shouldSendHeartbeat: @escaping @Sendable () -> Void) {
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
