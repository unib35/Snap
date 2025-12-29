import Foundation
import Network

/// TCP 서버 델리게이트
public protocol TCPServerDelegate: AnyObject, Sendable {
    func tcpServer(_ server: TCPServer, didAccept connection: TCPConnection)
    func tcpServer(_ server: TCPServer, didFailWithError error: Error)
}

/// TCP 서버 (macOS에서 사용)
public final class TCPServer: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: TCPServerDelegate?

    private var listener: NWListener?
    private let port: UInt16
    private let queue: DispatchQueue

    public private(set) var isListening: Bool = false

    // MARK: - Initialization

    public init(port: UInt16 = NetworkConstants.tcpPort) {
        self.port = port
        self.queue = DispatchQueue(label: "com.snap.tcp.server", qos: .userInteractive)
    }

    // MARK: - Public Methods

    /// 서버 시작
    public func start() throws {
        guard !isListening else { return }

        let parameters = NWParameters.tcp
        parameters.prohibitExpensivePaths = false
        parameters.prohibitedInterfaceTypes = [.cellular]
        parameters.allowLocalEndpointReuse = true

        listener = try NWListener(using: parameters, on: NWEndpoint.Port(rawValue: port)!)

        listener?.stateUpdateHandler = { [weak self] state in
            self?.handleListenerState(state)
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.start(queue: queue)
    }

    /// 서버 중지
    public func stop() {
        guard isListening else { return }
        listener?.cancel()
        listener = nil
        isListening = false
    }

    // MARK: - Private Methods

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .setup:
            break

        case .waiting(let error):
            print("[TCP Server] Waiting: \(error.localizedDescription)")

        case .ready:
            isListening = true
            if let port = listener?.port {
                print("[TCP Server] Listening on port \(port.rawValue)")
            }

        case .failed(let error):
            isListening = false
            delegate?.tcpServer(self, didFailWithError: error)

        case .cancelled:
            isListening = false

        @unknown default:
            break
        }
    }

    private func handleNewConnection(_ nwConnection: NWConnection) {
        let connection = TCPConnection(connection: nwConnection)
        connection.connect()
        delegate?.tcpServer(self, didAccept: connection)
    }
}
