import Foundation
import Network
import os

private let logger = Logger(subsystem: "com.snap.shared", category: "TCPServer")

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
    private let useTLS: Bool
    private let tlsOptions: NWProtocolTLS.Options?

    public private(set) var isListening: Bool = false

    // Bonjour 서비스 설정
    private var bonjourServiceName: String?
    private var bonjourServiceType: String?
    private var txtRecord: NWTXTRecord?

    // MARK: - Initialization

    public init(port: UInt16 = NetworkConstants.tcpPort, useTLS: Bool = false, tlsOptions: NWProtocolTLS.Options? = nil) {
        self.port = port
        self.useTLS = useTLS
        self.tlsOptions = tlsOptions
        self.queue = DispatchQueue(label: "com.snap.tcp.server", qos: .userInteractive)
    }

    /// Bonjour 서비스 설정 (start() 호출 전에 설정)
    public func setBonjourService(name: String, type: String, txtRecord: NWTXTRecord? = nil) {
        self.bonjourServiceName = name
        self.bonjourServiceType = type
        self.txtRecord = txtRecord
    }

    /// TXT 레코드 업데이트
    public func updateTXTRecord(_ record: NWTXTRecord) {
        self.txtRecord = record
        if let listener = listener {
            listener.service = NWListener.Service(
                name: bonjourServiceName ?? "",
                type: bonjourServiceType ?? NetworkConstants.bonjourServiceTypeTCP,
                txtRecord: record
            )
        }
    }

    // MARK: - Public Methods

    /// 서버 시작
    public func start() throws {
        guard !isListening else { return }

        let parameters: NWParameters
        if useTLS {
            guard let options = tlsOptions ?? SecurityManager.shared.createServerTLSOptions() else {
                throw NetworkError.connectionFailed(NSError(
                    domain: "TCPServer",
                    code: -2,
                    userInfo: [NSLocalizedDescriptionKey: "Failed to create TLS options"]
                ))
            }
            parameters = NWParameters(tls: options)
            logger.info("Starting TLS-secured TCP server on port \(self.port)")
        } else {
            parameters = NWParameters.tcp
        }
        parameters.prohibitExpensivePaths = false
        parameters.prohibitedInterfaceTypes = [.cellular]
        parameters.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NetworkError.connectionFailed(NSError(domain: "TCPServer", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid port"]))
        }
        listener = try NWListener(using: parameters, on: nwPort)

        // Bonjour 서비스 등록 (설정된 경우)
        if let serviceName = bonjourServiceName, let serviceType = bonjourServiceType {
            listener?.service = NWListener.Service(
                name: serviceName,
                type: serviceType,
                txtRecord: txtRecord ?? NWTXTRecord()
            )
            logger.info("Registering Bonjour service: \(serviceName) (\(serviceType))")
        }

        listener?.stateUpdateHandler = { [weak self] state in
            self?.handleListenerState(state)
        }

        listener?.newConnectionHandler = { [weak self] connection in
            self?.handleNewConnection(connection)
        }

        listener?.serviceRegistrationUpdateHandler = { change in
            switch change {
            case .add(let endpoint):
                if case .service(let name, let type, let domain, _) = endpoint {
                    logger.info("Bonjour registered: \(name).\(type)\(domain)")
                }
            case .remove(let endpoint):
                if case .service(let name, let type, let domain, _) = endpoint {
                    logger.info("Bonjour unregistered: \(name).\(type)\(domain)")
                }
            @unknown default:
                break
            }
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
            logger.debug("Waiting: \(error.localizedDescription)")

        case .ready:
            isListening = true
            if let port = listener?.port {
                logger.info("Listening on port \(port.rawValue)")
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
        let connection = TCPConnection(connection: nwConnection, isSecure: useTLS)
        connection.connect()
        delegate?.tcpServer(self, didAccept: connection)
    }
}
