import Foundation
import Network

/// TCP 연결 델리게이트
public protocol TCPConnectionDelegate: AnyObject, Sendable {
    func tcpConnectionDidConnect(_ connection: TCPConnection)
    func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?)
    func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket)
}

/// TCP 연결 (NWConnection 래퍼)
public final class TCPConnection: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: TCPConnectionDelegate?

    private let connection: NWConnection
    private let queue: DispatchQueue

    public private(set) var state: ConnectionState = .disconnected

    // MARK: - Initialization

    /// 클라이언트로 초기화 (호스트에 연결)
    public init(host: String, port: UInt16) {
        let endpoint = NWEndpoint.hostPort(
            host: NWEndpoint.Host(host),
            port: NWEndpoint.Port(rawValue: port)!
        )
        let parameters = NWParameters.tcp
        parameters.prohibitExpensivePaths = false
        parameters.prohibitedInterfaceTypes = [.cellular]

        self.connection = NWConnection(to: endpoint, using: parameters)
        self.queue = DispatchQueue(label: "com.snap.tcp.client", qos: .userInteractive)

        setupConnection()
    }

    /// 서버로부터 수락된 연결로 초기화
    public init(connection: NWConnection) {
        self.connection = connection
        self.queue = DispatchQueue(label: "com.snap.tcp.server", qos: .userInteractive)

        setupConnection()
    }

    // MARK: - Public Methods

    /// 연결 시작
    public func connect() {
        guard state == .disconnected else { return }
        state = .connecting
        connection.start(queue: queue)
    }

    /// 연결 종료
    public func disconnect() {
        guard state == .connected || state == .connecting else { return }
        state = .disconnecting
        connection.cancel()
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
        switch newState {
        case .setup:
            break

        case .preparing:
            break

        case .ready:
            state = .connected
            delegate?.tcpConnectionDidConnect(self)
            startReceiving()

        case .waiting(let error):
            // 재연결 대기 중
            print("[TCP] Waiting: \(error.localizedDescription)")

        case .failed(let error):
            state = .disconnected
            delegate?.tcpConnectionDidDisconnect(self, error: error)

        case .cancelled:
            state = .disconnected
            delegate?.tcpConnectionDidDisconnect(self, error: nil)

        @unknown default:
            break
        }
    }

    private func startReceiving() {
        receiveHeader()
    }

    private func receiveHeader() {
        // 먼저 16바이트 헤더를 읽음
        connection.receive(
            minimumIncompleteLength: NetworkConstants.packetHeaderSize,
            maximumLength: NetworkConstants.packetHeaderSize
        ) { [weak self] content, _, isComplete, error in
            guard let self else { return }

            if let error {
                self.handleReceiveError(error)
                return
            }

            if isComplete {
                self.state = .disconnected
                self.delegate?.tcpConnectionDidDisconnect(self, error: nil)
                return
            }

            guard let headerData = content,
                  let header = PacketHeader(data: headerData) else {
                self.receiveHeader()
                return
            }

            // 페이로드 읽기
            self.receivePayload(header: header, headerData: headerData)
        }
    }

    private func receivePayload(header: PacketHeader, headerData: Data) {
        let payloadLength = Int(header.payloadLength)

        guard payloadLength > 0 else {
            // 빈 페이로드인 경우
            processPacket(headerData)
            receiveHeader()
            return
        }

        connection.receive(
            minimumIncompleteLength: payloadLength,
            maximumLength: payloadLength
        ) { [weak self] content, _, isComplete, error in
            guard let self else { return }

            if let error {
                self.handleReceiveError(error)
                return
            }

            if isComplete {
                self.state = .disconnected
                self.delegate?.tcpConnectionDidDisconnect(self, error: nil)
                return
            }

            guard let payloadData = content else {
                self.receiveHeader()
                return
            }

            var fullPacket = headerData
            fullPacket.append(payloadData)

            self.processPacket(fullPacket)
            self.receiveHeader()
        }
    }

    private func processPacket(_ data: Data) {
        do {
            let packet = try PacketDecoder.decode(data)
            delegate?.tcpConnection(self, didReceive: packet)
        } catch {
            print("[TCP] Packet decode error: \(error)")
        }
    }

    private func handleReceiveError(_ error: NWError) {
        if case .posix(let code) = error, code == .ECANCELED {
            // 정상 종료
            return
        }
        print("[TCP] Receive error: \(error.localizedDescription)")
    }
}
