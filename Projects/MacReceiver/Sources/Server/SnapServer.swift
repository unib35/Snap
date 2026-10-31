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
    /// 페어링 PIN 코드 표시 요청 (새 디바이스 연결 시)
    func server(_ server: SnapServer, showPairingCode code: String, forDevice deviceName: String)
    /// 페어링 완료 (PIN 입력 완료)
    func server(_ server: SnapServer, didCompletePairing success: Bool, deviceName: String)
}

/// Snap 서버 (macOS)
///
/// - Note: `@unchecked Sendable` - 네트워크 컴포넌트들이 각자 내부 큐를 통해 스레드 안전하게 동작함
public final class SnapServer: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: SnapServerDelegate?

    private var tcpServer: TCPServer?
    private var udpSocket: UDPSocket?

    private var connectedClient: TCPConnection?
    private let lock = NSRecursiveLock()
    private let lifecycleQueue = DispatchQueue(label: "com.snap.server.lifecycle")
    private var connections: [ObjectIdentifier: TCPConnection] = [:]
    private var connectionTimeouts: [ObjectIdentifier: DispatchWorkItem] = [:]
    private var udpSessionID: UUID?
    private var udpSessionKey: Data?

    private var heartbeatManager: HeartbeatManager?

    private let deviceName: String
    private let deviceID: String

    public private(set) var isRunning: Bool = false
    public private(set) var connectedDeviceName: String?
    private var connectedDeviceID: String?

    // Pairing State
    private var pendingPairingConnection: TCPConnection?
    private var pendingPairingDeviceID: String?
    private var pendingPairingDeviceName: String?
    private var currentPIN: String?
    private var pendingPairingNonce: Data?
    private var pendingPairingDeadline: DispatchTime?
    private let credentialStore: any PairingCredentialStore
    private let certificateData: @Sendable () -> Data?
    private let trustedDevicesManager: TrustedDevicesManager

    /// Production transports cannot opt out of TLS or pairing.
    public let useSecureConnection = true

    // MARK: - Initialization

    public init(
        deviceName: String? = nil,
        credentialStore: any PairingCredentialStore = KeychainPairingCredentialStore.shared,
        certificateData: @escaping @Sendable () -> Data? = { SecurityManager.shared.exportCertificateData() },
        trustedDevicesManager: TrustedDevicesManager = .shared
    ) {
        self.deviceName = deviceName ?? Host.current().localizedName ?? "Mac"
        self.deviceID = Self.getDeviceID()
        self.credentialStore = credentialStore
        self.certificateData = certificateData
        self.trustedDevicesManager = trustedDevicesManager
    }

    // MARK: - Public Methods

    /// 서버 시작
    public func start() throws {
        lock.lock()
        defer { lock.unlock() }
        guard !isRunning else { return }

        // TCP 서버 시작 (TLS 옵션 적용)
        if useSecureConnection {
            logger.info("Starting server with TLS and authenticated UDP encryption")
        }
        tcpServer = TCPServer(useTLS: useSecureConnection)
        tcpServer?.delegate = self

        // Bonjour 서비스를 TCPServer에 직접 등록 (별도 listener 충돌 방지)
        var txtRecord = NWTXTRecord()
        txtRecord["deviceID"] = deviceID
        txtRecord["secure"] = useSecureConnection ? "1" : "0"
        tcpServer?.setBonjourService(
            name: deviceName,
            type: NetworkConstants.bonjourServiceTypeTCP,
            txtRecord: txtRecord
        )

        do {
            try tcpServer?.start()
            // UDP 소켓 시작 (리슨 모드, DTLS 옵션 적용)
            udpSocket = UDPSocket(role: .server)
            udpSocket?.delegate = self
            try udpSocket?.listen()
        } catch {
            stop()
            throw error
        }

        isRunning = true
        delegate?.serverDidStart(self)
    }

    /// 서버 중지
    public func stop() {
        lock.lock()
        defer { lock.unlock() }
        let wasRunning = isRunning
        cancelPairing()
        disconnectClient()
        for timeout in connectionTimeouts.values { timeout.cancel() }
        connectionTimeouts.removeAll()
        let clients = Array(connections.values)
        connections.removeAll()
        for client in clients { client.cancel() }
        tcpServer?.stop()
        tcpServer = nil
        udpSocket?.close()
        udpSocket = nil
        isRunning = false
        if wasRunning { delegate?.serverDidStop(self) }
    }

    /// 클라이언트 연결 해제
    public func disconnectClient() {
        lock.lock()
        defer { lock.unlock() }
        guard let client = connectedClient else { return }
        connectedClient = nil
        let name = connectedDeviceName
        connectedDeviceName = nil
        connectedDeviceID = nil
        udpSessionKey = nil
        udpSessionID = nil
        udpSocket?.setSessionKey(nil)
        heartbeatManager?.stop()
        heartbeatManager = nil
        client.disconnect()
        if let name { delegate?.server(self, didDisconnectFrom: name) }
    }

    // MARK: - Trusted Devices

    /// 신뢰한 iPhone 목록 (페어링한 순서)
    public var trustedDevices: [TrustedDevice] {
        trustedDevicesManager.trustedDevices
    }

    /// 신뢰한 iPhone을 지웁니다.
    ///
    /// 인증 토큰도 함께 지우므로 그 기기는 다음 연결 때 QR 페어링을 다시 해야 합니다.
    /// 지금 연결된 기기면 연결을 끊습니다.
    public func revokeTrustedDevice(deviceID: String) throws {
        lock.lock()
        defer { lock.unlock() }
        trustedDevicesManager.removeTrustedDevice(deviceID: deviceID)
        try credentialStore.remove(for: "server:" + deviceID)
        if connectedDeviceID == deviceID {
            disconnectClient()
        }
    }

    /// 앱 목록 응답 전송
    public func sendAppListResponse(_ response: AppListResponse) {
        lock.lock()
        defer { lock.unlock() }
        guard let client = connectedClient else { return }
        client.send(response, type: .appListResponse)
    }

    /// Now Playing 정보 전송
    public func sendNowPlayingInfo(_ info: NowPlayingInfo) {
        lock.lock()
        defer { lock.unlock() }
        guard let client = connectedClient else { return }
        client.send(info, type: .nowPlayingInfo)
    }

    /// 시스템 볼륨 상태 전송
    public func sendVolumeState(_ state: VolumeState) {
        lock.lock()
        defer { lock.unlock() }
        guard let client = connectedClient else { return }
        client.send(state, type: .volumeState)
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

    private func sendHandshakeResponse(to connection: TCPConnection, token: Data) {
        let handshake = Handshake(
            deviceName: deviceName,
            deviceID: deviceID,
            protocolVersion: UInt32(NetworkConstants.protocolVersion),
            appVersion: "1.0.0",
            udpSessionKey: udpSessionKey,
            authenticationToken: token
        )
        connection.send(handshake, type: .handshake)
    }

    private func handleHandshake(_ handshake: Handshake, from connection: TCPConnection) {
        guard connections[ObjectIdentifier(connection)] != nil else { return }
        guard connectedClient !== connection, pendingPairingConnection !== connection else { return }
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

        if let pending = pendingPairingConnection, pending !== connection {
            connection.disconnect()
            return
        }
        guard connection.isSecure, !handshake.deviceID.isEmpty, handshake.deviceID.utf8.count <= 256 else {
            connection.cancel()
            return
        }
        do {
            if trustedDevicesManager.isTrusted(deviceID: handshake.deviceID),
               let saved = try credentialStore.load(for: "server:" + handshake.deviceID),
               let supplied = handshake.authenticationToken,
               saved.matches(supplied) {
                acceptConnection(handshake: handshake, connection: connection, token: saved.token)
            } else {
                // Legacy device IDs do not establish trust. Re-pair by scanning
                // a fresh code; no downgrade to plaintext or ID-only approval.
                startPairing(handshake: handshake, connection: connection)
            }
        } catch {
            delegate?.server(self, didFailWithError: error)
            connection.cancel()
        }
    }

    private func startPairing(handshake: Handshake, connection: TCPConnection) {
        guard let certificate = certificateData() else {
            connection.cancel()
            return
        }
        let secret = DatagramSession.makeKey().base64EncodedString()
        let nonce = DatagramSession.makeKey()
        let code = PairingDisplayCode(serverID: deviceID, certificate: certificate, challenge: nonce, pin: secret)
        guard let display = try? code.encoded() else { connection.cancel(); return }
        currentPIN = secret
        pendingPairingNonce = nonce
        pendingPairingDeadline = .now() + 60
        pendingPairingConnection = connection
        pendingPairingDeviceID = handshake.deviceID
        pendingPairingDeviceName = handshake.deviceName
        let challenge = PairingChallenge(deviceName: deviceName, deviceID: deviceID, nonce: nonce)
        connection.send(challenge, type: .pairingChallenge)
        scheduleTimeout(for: connection, after: 60)
        delegate?.server(self, showPairingCode: display, forDevice: handshake.deviceName)
    }

    private func handlePairingResponse(_ response: PairingResponse, from connection: TCPConnection) {
        guard connection === pendingPairingConnection,
              let expectedPIN = currentPIN,
              let deadline = pendingPairingDeadline, DispatchTime.now() < deadline,
              response.deviceID == pendingPairingDeviceID,
              response.nonce == pendingPairingNonce else {
            // 잘못된 페어링 응답
            let result = PairingResult(status: .rejected, message: "Invalid pairing session")
            connection.send(result, type: .pairingResult)
            connection.disconnect()
            // A foreign response must not cancel another device's pairing.
            return
        }

        // PIN 확인
        if response.pinCode == expectedPIN {
            let token = DatagramSession.makeKey()
            do {
                try credentialStore.save(PairingCredential(token: token), for: "server:" + response.deviceID)
            } catch {
                connection.cancel()
                delegate?.server(self, didCompletePairing: false, deviceName: response.deviceName)
                delegate?.server(self, didFailWithError: error)
                clearPairingState()
                return
            }
            trustedDevicesManager.addTrustedDevice(
                deviceID: response.deviceID,
                deviceName: response.deviceName
            )

            let result = PairingResult(status: .success, message: "Pairing successful")
            connection.send(result, type: .pairingResult)

            logger.info("Pairing successful for device: \(response.deviceName)")
            delegate?.server(self, didCompletePairing: true, deviceName: response.deviceName)

            // 연결 수락
            let handshake = Handshake(
                deviceName: response.deviceName,
                deviceID: response.deviceID,
                protocolVersion: UInt32(NetworkConstants.protocolVersion),
                appVersion: "1.0.0"
            )
            acceptConnection(handshake: handshake, connection: connection, token: token)
            clearPairingState()
        } else {
            // PIN 불일치
            let result = PairingResult(status: .invalidPin, message: "Invalid PIN code")
            connection.send(result, type: .pairingResult)
            connection.disconnect()

            logger.warning("Pairing failed: Invalid PIN for device: \(response.deviceName)")
            delegate?.server(self, didCompletePairing: false, deviceName: response.deviceName)
            clearPairingState()
        }
    }

    private func acceptConnection(handshake: Handshake, connection: TCPConnection, token: Data) {
        connectionTimeouts.removeValue(forKey: ObjectIdentifier(connection))?.cancel()
        connectedClient = connection
        connectedDeviceName = handshake.deviceName
        connectedDeviceID = handshake.deviceID
        udpSessionKey = DatagramSession.makeKey()
        udpSessionID = udpSocket?.setSessionKey(udpSessionKey)

        // 핸드셰이크 응답 전송
        sendHandshakeResponse(to: connection, token: token)

        // 하트비트 시작
        setupHeartbeat()

        delegate?.server(self, didAcceptConnection: handshake.deviceName)
    }

    private func scheduleTimeout(for connection: TCPConnection, after seconds: TimeInterval) {
        let id = ObjectIdentifier(connection)
        connectionTimeouts.removeValue(forKey: id)?.cancel()
        let work = DispatchWorkItem { [weak self, weak connection] in
            guard let self, let connection else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            guard self.connections[id] != nil, self.connectedClient !== connection else { return }
            connection.disconnect()
        }
        connectionTimeouts[id] = work
        lifecycleQueue.asyncAfter(deadline: .now() + seconds, execute: work)
    }

    private func clearPairingState() {
        currentPIN = nil
        pendingPairingNonce = nil
        pendingPairingDeadline = nil
        pendingPairingConnection = nil
        pendingPairingDeviceID = nil
        pendingPairingDeviceName = nil
    }

    /// 페어링 취소
    public func cancelPairing() {
        lock.lock()
        defer { lock.unlock() }
        guard let connection = pendingPairingConnection else { return }

        let result = PairingResult(status: .rejected, message: "Pairing cancelled by user")
        connection.send(result, type: .pairingResult)
        connection.disconnect()

        if let deviceName = pendingPairingDeviceName {
            delegate?.server(self, didCompletePairing: false, deviceName: deviceName)
        }
        clearPairingState()
    }
}

// MARK: - TCPServerDelegate

extension SnapServer: TCPServerDelegate {
    public func tcpServer(_ server: TCPServer, didAccept connection: TCPConnection) {
        lock.lock()
        defer { lock.unlock() }
        guard server === tcpServer else {
            connection.cancel()
            return
        }
        acceptTransportConnection(connection)
    }

    // Separate registration from the listener callback so the session boundary
    // can be exercised without opening ports or generating real input events.
    func acceptTransportConnection(_ connection: TCPConnection) {
        lock.lock()
        defer { lock.unlock() }
        guard connection.isSecure, connections.count < 16 else {
            // Mark the unstarted connection cancelled before TCPServer starts it.
            connection.delegate = nil
            connection.cancel()
            return
        }
        connections[ObjectIdentifier(connection)] = connection
        connection.delegate = self
        scheduleTimeout(for: connection, after: NetworkConstants.connectionTimeout)
        logger.debug("Accepted TCP connection")
    }

    public func tcpServer(_ server: TCPServer, didFailWithError error: Error) {
        lock.lock()
        defer { lock.unlock() }
        guard server === tcpServer else { return }
        stop()
        delegate?.server(self, didFailWithError: error)
    }
}

// MARK: - TCPConnectionDelegate

extension SnapServer: TCPConnectionDelegate {
    public func tcpConnectionDidConnect(_ connection: TCPConnection) {
        // 연결 수락 시 처리됨
    }

    public func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?) {
        lock.lock()
        defer { lock.unlock() }
        connections.removeValue(forKey: ObjectIdentifier(connection))
        connectionTimeouts.removeValue(forKey: ObjectIdentifier(connection))?.cancel()
        if connection === pendingPairingConnection {
            let name = pendingPairingDeviceName ?? ""
            clearPairingState()
            delegate?.server(self, didCompletePairing: false, deviceName: name)
        }
        if connection === connectedClient { disconnectClient() }
    }

    public func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket) {
        lock.lock()
        defer { lock.unlock() }
        guard connections[ObjectIdentifier(connection)] != nil else { return }
        switch packet {
        case .handshake, .pairingResponse, .disconnect:
            break
        default:
            guard connection === connectedClient else {
                connection.disconnect()
                return
            }
            heartbeatManager?.didReceiveMessage()
        }

        switch packet {
        case .handshake(let handshake, _):
            handleHandshake(handshake, from: connection)

        case .pairingResponse(let response, _):
            handlePairingResponse(response, from: connection)

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
        lock.lock()
        defer { lock.unlock() }
        logger.debug("UDP socket ready")
    }

    public func udpSocket(_ socket: UDPSocket, didReceive packet: DecodedPacket, from endpoint: NetworkEndpoint, sessionID: UUID) {
        lock.lock()
        defer { lock.unlock() }
        guard connectedClient != nil, socket === udpSocket, sessionID == udpSessionID else { return }
        // UDPSocket has already verified the current session signature and sequence.
        switch packet {
        case .mouseMove, .scroll, .gyroData, .pinch:
            delegate?.server(self, didReceivePacket: packet)
        default:
            break
        }
    }

    public func udpSocket(_ socket: UDPSocket, didFailWithError error: Error) {
        lock.lock()
        defer { lock.unlock() }
        guard socket === udpSocket else { return }
        stop()
        delegate?.server(self, didFailWithError: error)
    }
}


// MARK: - HeartbeatManagerDelegate

extension SnapServer: HeartbeatManagerDelegate {
    public func heartbeatManagerDidTimeout(_ manager: HeartbeatManager) {
        lock.lock()
        defer { lock.unlock() }
        guard manager === heartbeatManager else { return }
        logger.warning("Heartbeat timeout")
        disconnectClient()
    }

    public func heartbeatManager(_ manager: HeartbeatManager, shouldSendHeartbeat: @escaping @Sendable () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        guard manager === heartbeatManager, let client = connectedClient else { return }

        let heartbeat = HeartbeatManager.createHeartbeat()
        client.send(heartbeat, type: .heartbeat) { _ in
            shouldSendHeartbeat()
        }
    }
}

// MARK: - Network Endpoint Typealias

import Network

public typealias NetworkEndpoint = NWEndpoint
