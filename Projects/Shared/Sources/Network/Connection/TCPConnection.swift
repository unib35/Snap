import Foundation
import Network
import os

private let logger = NetworkLogger.tcp

/// TCP 연결 델리게이트
public protocol TCPConnectionDelegate: AnyObject, Sendable {
    func tcpConnectionDidConnect(_ connection: TCPConnection)
    func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?)
    func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket)
}

/// TCP 연결 (NWConnection 래퍼)
///
/// - Note: `@unchecked Sendable` - 내부 DispatchQueue(`queue`)를 통해 모든 상태 접근이 직렬화되어 스레드 안전함
public final class TCPConnection: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: TCPConnectionDelegate?

    private let connection: NWConnection
    private let queue: DispatchQueue

    private let lock = NSRecursiveLock()
    private var storedState: ConnectionState = .disconnected
    private var hasFinished = false
    private var receiveBuffer = Data()

    public var state: ConnectionState {
        lock.lock()
        defer { lock.unlock() }
        return storedState
    }
    public let isSecure: Bool

    /// 연결 타임아웃 (초)
    public var connectionTimeout: TimeInterval

    private var timeoutWorkItem: DispatchWorkItem?

    // MARK: - Initialization

    /// 클라이언트로 초기화 (호스트에 연결)
    public init(
        host: String,
        port: UInt16,
        useTLS: Bool = false,
        tlsOptions: NWProtocolTLS.Options? = nil,
        timeout: TimeInterval = NetworkConstants.connectionTimeout
    ) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port) ?? .any
        )

        let parameters: NWParameters
        if useTLS {
            let options = tlsOptions ?? SecurityManager.shared.createClientTLSOptions()
            parameters = NWParameters(tls: options)
            self.isSecure = true
            logger.info("Creating TLS-secured TCP connection to \(host):\(port)")
        } else {
            parameters = NWParameters.tcp
            self.isSecure = false
        }
        parameters.prohibitExpensivePaths = false
        parameters.prohibitedInterfaceTypes = [.cellular]

        self.connection = NWConnection(to: endpoint, using: parameters)
        self.queue = DispatchQueue(label: "com.snap.tcp.client", qos: .userInteractive)
        self.connectionTimeout = timeout

        setupConnection()
    }

    /// 서버로부터 수락된 연결로 초기화
    public init(connection: NWConnection, isSecure: Bool = false) {
        self.connection = connection
        self.isSecure = isSecure
        self.queue = DispatchQueue(label: "com.snap.tcp.server", qos: .userInteractive)
        self.connectionTimeout = NetworkConstants.connectionTimeout

        setupConnection()
    }

    deinit {
        cancelTimeoutTimer()
        connection.cancel()
    }

    // MARK: - Public Methods

    /// 연결 시작
    public func connect() {
        lock.lock()
        defer { lock.unlock() }
        guard state == .disconnected, !hasFinished else { return }
        storedState = .connecting

        // 타임아웃 타이머 시작
        startTimeoutTimer()

        connection.start(queue: queue)
    }

    /// 연결 종료
    public func disconnect() {
        lock.lock()
        defer { lock.unlock() }
        guard state == .connected || state == .connecting else { return }
        finish(error: nil)
    }

    /// Cancels even a not-yet-started accepted connection.
    public func cancel() {
        lock.lock()
        defer { lock.unlock() }
        finish(error: nil)
    }

    // MARK: - Timeout

    private func startTimeoutTimer() {
        cancelTimeoutTimer()

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            guard self.state == .connecting else { return }
            self.finish(error: ConnectionTimeoutError())
        }

        timeoutWorkItem = workItem
        queue.asyncAfter(deadline: .now() + connectionTimeout, execute: workItem)
    }

    private func cancelTimeoutTimer() {
        timeoutWorkItem?.cancel()
        timeoutWorkItem = nil
    }

    /// 데이터 전송
    public func send(_ data: Data, completion: (@Sendable (Error?) -> Void)? = nil) {
        connection.send(
            content: data,
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

    // MARK: - Private Methods

    private func setupConnection() {
        connection.stateUpdateHandler = { [weak self] state in
            guard let self else { return }
            self.handleStateChange(state)
        }
    }

    private func handleStateChange(_ newState: NWConnection.State) {
        lock.lock()
        defer { lock.unlock() }
        guard !hasFinished else { return }
        let previousState = state

        switch newState {
        case .setup:
            logger.debug("Connection setup")

        case .preparing:
            logger.debug("Connection preparing")

        case .ready:
            cancelTimeoutTimer()
            storedState = .connected
            NetworkLogger.logConnectionStateChange(
                from: previousState.description,
                to: "connected"
            )
            lock.unlock()
            delegate?.tcpConnectionDidConnect(self)
            lock.lock()
            if !hasFinished { startReceiving() }

        case .waiting(let error):
            // Network.framework reports certificate rejection as .waiting.
            // Retrying cannot repair trust; surface the TLS error immediately.
            if case .tls = error {
                finish(error: error)
            } else {
                logger.warning("Connection waiting: \(error.localizedDescription)")
            }

        case .failed(let error):
            finish(error: error)

        case .cancelled:
            finish(error: nil)

        @unknown default:
            logger.warning("Unknown connection state")
        }
    }

    private func startReceiving() {
        connection.receive(minimumIncompleteLength: 1, maximumLength: NetworkConstants.maxPacketSize) { [weak self] content, _, isComplete, error in
            guard let self else { return }
            self.lock.lock()
            defer { self.lock.unlock() }
            guard !self.hasFinished else { return }

            // A final callback can contain data as well as EOF.
            if let content {
                self.receiveBuffer.append(content)
                self.drainPackets()
            }
            guard !self.hasFinished else { return }
            if let error {
                self.finish(error: error)
            } else if isComplete {
                self.finish(error: self.receiveBuffer.isEmpty ? nil : PacketDecodingError.payloadTooShort)
            } else if self.state == .connected {
                self.startReceiving()
            }
        }
    }

    private func drainPackets() {
        while !hasFinished && receiveBuffer.count >= NetworkConstants.packetHeaderSize {
            guard let header = PacketHeader(data: receiveBuffer),
                  header.isExactVersionMatch,
                  header.payloadLength <= NetworkConstants.maxTCPPayloadSize else {
                finish(error: PacketDecodingError.invalidHeader)
                return
            }
            let length = NetworkConstants.packetHeaderSize + Int(header.payloadLength)
            guard receiveBuffer.count >= length else { return }
            let data = Data(receiveBuffer.prefix(length))
            receiveBuffer = Data(receiveBuffer.dropFirst(length))
            do {
                let packet = try PacketDecoder.decode(data)
                lock.unlock()
                delegate?.tcpConnection(self, didReceive: packet)
                lock.lock()
            } catch {
                finish(error: error)
            }
        }
    }

    private func finish(error: Error?) {
        guard !hasFinished else { return }
        hasFinished = true
        cancelTimeoutTimer()
        storedState = .disconnected
        receiveBuffer.removeAll()
        connection.cancel()
        // Deliver outside the connection lock to avoid lock inversion with owners.
        queue.async { [self] in
            delegate?.tcpConnectionDidDisconnect(self, error: error)
        }
    }
}
