import Foundation
import Network
import os

private let logger = NetworkLogger.udp

/// UDP 소켓 델리게이트
public protocol UDPSocketDelegate: AnyObject, Sendable {
    func udpSocketDidReady(_ socket: UDPSocket)
    func udpSocket(_ socket: UDPSocket, didReceive packet: DecodedPacket, from endpoint: NWEndpoint, sessionID: UUID)
    func udpSocket(_ socket: UDPSocket, didFailWithError error: Error)
}

/// UDP 소켓 (양방향 통신)
///
/// - Note: `@unchecked Sendable` - 내부 DispatchQueue(`queue`)를 통해 모든 상태 접근이 직렬화되어 스레드 안전함
public final class UDPSocket: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: UDPSocketDelegate?

    private var connection: NWConnection?
    private var listener: NWListener?
    private var lastActivity: [ObjectIdentifier: Date] = [:]
    private var acceptedConnections: [ObjectIdentifier: NWConnection] = [:]
    private let sessionLock = NSLock()
    private var session: DatagramSession?
    private let sessionRole: DatagramSession.Role

    @discardableResult
    public func setSessionKey(_ key: Data?) -> UUID? {
        sessionLock.lock()
        session = key.flatMap { DatagramSession(key: $0, role: sessionRole) }
        let id = session?.id
        sessionLock.unlock()
        return id
    }

    private func currentSession() -> DatagramSession? {
        sessionLock.lock()
        defer { sessionLock.unlock() }
        return session
    }
    private let queue: DispatchQueue

    private let port: UInt16
    private var remoteEndpoint: NWEndpoint?
    private let useDTLS: Bool
    private let dtlsOptions: NWProtocolTLS.Options?

    public private(set) var isReady: Bool = false
    public let isSecure: Bool
    public var localPort: UInt16? { listener?.port?.rawValue }

    // MARK: - Initialization

    public init(port: UInt16 = NetworkConstants.udpPort, role: DatagramSession.Role = .client, useDTLS: Bool = false, dtlsOptions: NWProtocolTLS.Options? = nil) {
        self.port = port
        self.sessionRole = role
        self.useDTLS = useDTLS
        self.dtlsOptions = dtlsOptions
        self.isSecure = useDTLS
        self.queue = DispatchQueue(label: "com.snap.udp", qos: .userInteractive)
    }

    // MARK: - Client Mode

    /// 클라이언트로 연결 (iOS에서 사용)
    public func connect(to host: String, port: UInt16? = nil) {
        let targetPort = port ?? self.port
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: targetPort) ?? .any
        )

        let parameters: NWParameters
        if useDTLS {
            let options = dtlsOptions ?? SecurityManager.shared.createClientDTLSOptions()
            parameters = NWParameters(dtls: options, udp: NWProtocolUDP.Options())
            logger.info("Creating DTLS-secured UDP connection to \(host):\(targetPort)")
        } else {
            parameters = NWParameters.udp
        }
        parameters.prohibitExpensivePaths = false
        parameters.prohibitedInterfaceTypes = [.cellular]

        connection = NWConnection(to: endpoint, using: parameters)
        remoteEndpoint = endpoint

        connection?.stateUpdateHandler = { [weak self] state in
            self?.handleConnectionState(state)
        }

        connection?.start(queue: queue)
    }

    // MARK: - Server Mode

    /// 서버로 리슨 (macOS에서 사용)
    public func listen() throws {
        let parameters: NWParameters
        if useDTLS {
            guard let options = dtlsOptions ?? SecurityManager.shared.createServerDTLSOptions() else {
                throw NetworkError.connectionFailed(NSError(
                    domain: "UDPSocket",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create DTLS options"]
                ))
            }
            parameters = NWParameters(dtls: options, udp: NWProtocolUDP.Options())
            logger.info("Starting DTLS-secured UDP listener on port \(self.port)")
        } else {
            parameters = NWParameters.udp
        }
        parameters.prohibitExpensivePaths = false
        parameters.prohibitedInterfaceTypes = [.cellular]
        parameters.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NetworkError.connectionFailed(NSError(domain: "UDPSocket", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid port"]))
        }
        listener = try NWListener(using: parameters, on: nwPort)

        listener?.stateUpdateHandler = { [weak self] state in
            self?.handleListenerState(state)
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.start(queue: queue)
    }

    // MARK: - Common

    /// 소켓 닫기
    public func close() {
        connection?.cancel()
        connection = nil
        listener?.cancel()
        listener = nil
        isReady = false
        setSessionKey(nil)
        queue.async { [weak self] in
            guard let self else { return }
            for connection in self.acceptedConnections.values { connection.cancel() }
            self.acceptedConnections.removeAll()
            self.lastActivity.removeAll()
        }
    }

    /// 데이터 전송 (클라이언트 모드)
    public func send(_ data: Data, completion: (@Sendable (Error?) -> Void)? = nil) {
        guard let connection else {
            completion?(NetworkError.notConnected)
            return
        }

        guard let datagram = currentSession()?.seal(data) else {
            completion?(NetworkError.notConnected)
            return
        }
        connection.send(
            content: datagram,
            completion: .contentProcessed { error in
                completion?(error)
            }
        )
    }

    /// 패킷 전송
    public func send<T: Codable & Sendable>(
        _ message: T,
        type: MessageType,
        completion: (@Sendable (Error?) -> Void)? = nil
    ) {
        do {
            let data = try PacketEncoder.encode(message, type: type)
            send(data, completion: completion)
        } catch {
            completion?(error)
        }
    }

    /// 특정 엔드포인트로 데이터 전송 (서버 모드)
    public func send(_ data: Data, to endpoint: NWEndpoint, completion: (@Sendable (Error?) -> Void)? = nil) {
        guard let datagram = currentSession()?.seal(data) else {
            completion?(NetworkError.notConnected)
            return
        }
        let parameters: NWParameters
        if useDTLS {
            guard let options = dtlsOptions ?? SecurityManager.shared.createServerDTLSOptions() else {
                completion?(NetworkError.notConnected)
                return
            }
            parameters = NWParameters(dtls: options, udp: NWProtocolUDP.Options())
        } else {
            parameters = NWParameters.udp
        }
        let conn = NWConnection(to: endpoint, using: parameters)

        conn.stateUpdateHandler = { state in
            if case .ready = state {
                conn.send(content: datagram, completion: .contentProcessed { error in
                    completion?(error)
                    conn.cancel()
                })
            }
        }

        conn.start(queue: queue)
    }

    // MARK: - Private Methods

    private func handleConnectionState(_ state: NWConnection.State) {
        switch state {
        case .ready:
            isReady = true
            delegate?.udpSocketDidReady(self)
            startReceiving()

        case .failed(let error):
            isReady = false
            delegate?.udpSocket(self, didFailWithError: error)

        case .cancelled:
            isReady = false

        default:
            break
        }
    }

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .ready:
            isReady = true
            if let port = listener?.port {
                logger.info("Listening on port \(port.rawValue)")
            }
            delegate?.udpSocketDidReady(self)

        case .failed(let error):
            isReady = false
            delegate?.udpSocket(self, didFailWithError: error)

        case .cancelled:
            isReady = false

        default:
            break
        }
    }

    private func handleNewConnection(_ newConnection: NWConnection) {
        let id = ObjectIdentifier(newConnection)
        guard acceptedConnections.count < 32 else {
            newConnection.cancel()
            return
        }
        acceptedConnections[id] = newConnection
        lastActivity[id] = Date()
        scheduleExpiry(for: newConnection)
        newConnection.stateUpdateHandler = { [weak self, weak newConnection] state in
            guard let self, let conn = newConnection else { return }

            switch state {
            case .ready:
                self.receiveFromConnection(conn)
            case .failed, .cancelled:
                self.acceptedConnections.removeValue(forKey: id)
                self.lastActivity.removeValue(forKey: id)
            default:
                break
            }
        }


        newConnection.start(queue: queue)
    }

    private func startReceiving() {
        guard let connection else { return }
        receiveFromConnection(connection)
    }

    private func receiveFromConnection(_ conn: NWConnection) {
        conn.receiveMessage { [weak self] content, _, _, error in
            guard let self else { return }

            if let error {
                if case .posix(let code) = error, code == .ECANCELED {
                    return
                }
                logger.error("Receive error: \(error.localizedDescription)")
                conn.cancel()
                return
            }

            if let data = content {
                if self.processPacket(data, from: conn.endpoint) {
                    self.lastActivity[ObjectIdentifier(conn)] = Date()
                }
            }
            // isComplete means the datagram is complete, not that the flow ended.
            self.receiveFromConnection(conn)
        }
    }

    private func scheduleExpiry(for connection: NWConnection) {
        let id = ObjectIdentifier(connection)
        queue.asyncAfter(deadline: .now() + 15) { [weak self, weak connection] in
            guard let self, let connection, self.acceptedConnections[id] != nil else { return }
            if Date().timeIntervalSince(self.lastActivity[id] ?? .distantPast) >= 15 {
                self.acceptedConnections.removeValue(forKey: id)
                self.lastActivity.removeValue(forKey: id)
                connection.cancel()
            } else {
                self.scheduleExpiry(for: connection)
            }
        }
    }

    private func processPacket(_ data: Data, from endpoint: NWEndpoint?) -> Bool {
        do {
            guard let session = currentSession(), let payload = session.open(data) else { return false }
            let packet = try PacketDecoder.decode(payload)
            if let endpoint {
                delegate?.udpSocket(self, didReceive: packet, from: endpoint, sessionID: session.id)
            }
            return true
        } catch {
            logger.error("Packet decode error: \(error.localizedDescription)")
            return false
        }
    }
}

// MARK: - NetworkError

public enum NetworkError: Error, Sendable {
    case notConnected
    case connectionFailed(Error)
    case sendFailed(Error)
    case timeout
}
