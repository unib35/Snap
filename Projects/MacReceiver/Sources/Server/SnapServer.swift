import Foundation
import os
import Shared

private let logger = Logger(subsystem: "com.snap.receiver", category: "SnapServer")

/// Snap 서버 델리게이트
public protocol SnapServerDelegate: AnyObject {
    func serverDidStart(_ server: SnapServer)
    func serverDidStop(_ server: SnapServer)
    func server(_ server: SnapServer, didAcceptConnection deviceName: String)
    func server(_ server: SnapServer, didDisconnectFrom deviceName: String)
    func server(_ server: SnapServer, didReceivePacket packet: DecodedPacket)
    func server(_ server: SnapServer, didFailWithError error: Error)
}

/// Snap 서버 (macOS)
public final class SnapServer: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: SnapServerDelegate?

    private var tcpServer: TCPServer?
    private var udpSocket: UDPSocket?
    private var bonjourAdvertiser: BonjourAdvertiser?

    private var connectedClient: TCPConnection?
    private var clientEndpoint: NetworkEndpoint?

    private var heartbeatManager: HeartbeatManager?

    private let deviceName: String
    private let deviceID: String

    public private(set) var isRunning: Bool = false
    public private(set) var connectedDeviceName: String?

    // MARK: - Initialization

    public init(deviceName: String? = nil) {
        self.deviceName = deviceName ?? Host.current().localizedName ?? "Mac"
        self.deviceID = Self.getDeviceID()
    }

    // MARK: - Public Methods

    /// 서버 시작
    public func start() throws {
        guard !isRunning else { return }

        // TCP 서버 시작
        tcpServer = TCPServer()
        tcpServer?.delegate = self
        try tcpServer?.start()

        // UDP 소켓 시작 (리슨 모드)
        udpSocket = UDPSocket()
        udpSocket?.delegate = self
        try udpSocket?.listen()

        // Bonjour 광고 시작
        bonjourAdvertiser = BonjourAdvertiser(serviceName: deviceName)
        bonjourAdvertiser?.setTXTRecord("deviceID", value: deviceID)
        bonjourAdvertiser?.delegate = self
        try bonjourAdvertiser?.startAdvertising()

        isRunning = true
        delegate?.serverDidStart(self)
    }

    /// 서버 중지
    public func stop() {
        guard isRunning else { return }

        // 연결된 클라이언트에 연결 종료 알림
        if let client = connectedClient {
            let disconnect = Disconnect()
            client.send(disconnect, type: .disconnect)
        }

        heartbeatManager?.stop()
        heartbeatManager = nil

        tcpServer?.stop()
        tcpServer = nil

        udpSocket?.close()
        udpSocket = nil

        bonjourAdvertiser?.stopAdvertising()
        bonjourAdvertiser = nil

        connectedClient = nil
        connectedDeviceName = nil

        isRunning = false
        delegate?.serverDidStop(self)
    }

    /// 클라이언트 연결 해제
    public func disconnectClient() {
        guard let client = connectedClient else { return }

        let disconnect = Disconnect()
        client.send(disconnect, type: .disconnect)
        client.disconnect()

        connectedClient = nil
        if let name = connectedDeviceName {
            connectedDeviceName = nil
            delegate?.server(self, didDisconnectFrom: name)
        }
    }

    // MARK: - Private Methods

    private static func getDeviceID() -> String {
        // 하드웨어 UUID 또는 저장된 UUID 사용
        let defaults = UserDefaults.standard
        if let savedID = defaults.string(forKey: "SnapDeviceID") {
            return savedID
        }

        let newID = UUID().uuidString
        defaults.set(newID, forKey: "SnapDeviceID")
        return newID
    }

    private func setupHeartbeat() {
        heartbeatManager = HeartbeatManager(
            interval: HeartbeatManager.tcpInterval,
            timeout: HeartbeatManager.timeout
        )
        heartbeatManager?.delegate = self
        heartbeatManager?.start()
    }

    private func sendHandshakeResponse(to connection: TCPConnection) {
        let handshake = Handshake(
            deviceName: deviceName,
            deviceID: deviceID,
            protocolVersion: UInt32(NetworkConstants.protocolVersion),
            appVersion: "1.0.0"
        )
        connection.send(handshake, type: .handshake)
    }

    private func handleHandshake(_ handshake: Handshake, from connection: TCPConnection) {
        // 프로토콜 버전 확인
        guard handshake.protocolVersion == NetworkConstants.protocolVersion else {
            let error = SnapError(
                code: .unsupportedVersion,
                message: "Protocol version mismatch"
            )
            connection.send(error, type: .error)
            connection.disconnect()
            return
        }

        // 이미 연결된 클라이언트가 있다면 새 연결 거부
        if connectedClient != nil && connectedClient !== connection {
            let error = SnapError(
                code: .permissionDenied,
                message: "Another device is already connected"
            )
            connection.send(error, type: .error)
            connection.disconnect()
            return
        }

        connectedClient = connection
        connectedDeviceName = handshake.deviceName

        // 핸드셰이크 응답 전송
        sendHandshakeResponse(to: connection)

        // 하트비트 시작
        setupHeartbeat()

        delegate?.server(self, didAcceptConnection: handshake.deviceName)
    }
}

// MARK: - TCPServerDelegate

extension SnapServer: TCPServerDelegate {
    public func tcpServer(_ server: TCPServer, didAccept connection: TCPConnection) {
        connection.delegate = self
        logger.debug("Accepted TCP connection")
    }

    public func tcpServer(_ server: TCPServer, didFailWithError error: Error) {
        delegate?.server(self, didFailWithError: error)
    }
}

// MARK: - TCPConnectionDelegate

extension SnapServer: TCPConnectionDelegate {
    public func tcpConnectionDidConnect(_ connection: TCPConnection) {
        // 연결 수락 시 처리됨
    }

    public func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?) {
        if connection === connectedClient {
            heartbeatManager?.stop()
            heartbeatManager = nil

            if let name = connectedDeviceName {
                connectedDeviceName = nil
                connectedClient = nil
                delegate?.server(self, didDisconnectFrom: name)
            }
        }
    }

    public func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket) {
        heartbeatManager?.didReceiveMessage()

        switch packet {
        case .handshake(let handshake, _):
            handleHandshake(handshake, from: connection)

        case .heartbeat(let heartbeat, _):
            heartbeatManager?.didReceiveHeartbeat()
            // 하트비트 응답 전송
            let response = Ack(originalTimestamp: heartbeat.timestamp)
            connection.send(response, type: .ack)

        case .disconnect:
            connection.disconnect()

        default:
            // 다른 패킷은 델리게이트로 전달
            delegate?.server(self, didReceivePacket: packet)
        }
    }
}

// MARK: - UDPSocketDelegate

extension SnapServer: UDPSocketDelegate {
    public func udpSocketDidReady(_ socket: UDPSocket) {
        logger.debug("UDP socket ready")
    }

    public func udpSocket(_ socket: UDPSocket, didReceive packet: DecodedPacket, from endpoint: NetworkEndpoint) {
        heartbeatManager?.didReceiveMessage()

        // UDP 패킷은 델리게이트로 전달
        delegate?.server(self, didReceivePacket: packet)
    }

    public func udpSocket(_ socket: UDPSocket, didFailWithError error: Error) {
        delegate?.server(self, didFailWithError: error)
    }
}

// MARK: - BonjourAdvertiserDelegate

extension SnapServer: BonjourAdvertiserDelegate {
    public func bonjourAdvertiserDidStart(_ advertiser: BonjourAdvertiser) {
        logger.info("Bonjour advertising started: \(deviceName)")
    }

    public func bonjourAdvertiser(_ advertiser: BonjourAdvertiser, didFailWithError error: Error) {
        delegate?.server(self, didFailWithError: error)
    }
}

// MARK: - HeartbeatManagerDelegate

extension SnapServer: HeartbeatManagerDelegate {
    public func heartbeatManagerDidTimeout(_ manager: HeartbeatManager) {
        logger.warning("Heartbeat timeout")
        disconnectClient()
    }

    public func heartbeatManager(_ manager: HeartbeatManager, shouldSendHeartbeat: @escaping @Sendable () -> Void) {
        guard let client = connectedClient else { return }

        let heartbeat = HeartbeatManager.createHeartbeat()
        client.send(heartbeat, type: .heartbeat) { _ in
            shouldSendHeartbeat()
        }
    }
}

// MARK: - Network Endpoint Typealias

import Network

public typealias NetworkEndpoint = NWEndpoint
