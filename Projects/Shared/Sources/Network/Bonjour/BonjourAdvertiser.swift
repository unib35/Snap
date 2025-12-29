import Foundation
import Network
import os

private let logger = Logger(subsystem: "com.snap.shared", category: "BonjourAdvertiser")

/// Bonjour 광고자 델리게이트
public protocol BonjourAdvertiserDelegate: AnyObject, Sendable {
    func bonjourAdvertiserDidStart(_ advertiser: BonjourAdvertiser)
    func bonjourAdvertiser(_ advertiser: BonjourAdvertiser, didFailWithError error: Error)
}

/// Bonjour 서비스 광고자 (macOS에서 서비스 광고)
public final class BonjourAdvertiser: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: BonjourAdvertiserDelegate?

    private var listener: NWListener?
    private let serviceName: String
    private let serviceType: String
    private let port: UInt16
    private let queue: DispatchQueue

    private var txtRecord = NWTXTRecord()

    public private(set) var isAdvertising: Bool = false

    // MARK: - Initialization

    public init(
        serviceName: String,
        serviceType: String = NetworkConstants.bonjourServiceTypeTCP,
        port: UInt16 = NetworkConstants.tcpPort
    ) {
        self.serviceName = serviceName
        self.serviceType = serviceType
        self.port = port
        self.queue = DispatchQueue(label: "com.snap.bonjour.advertiser", qos: .userInitiated)
    }

    // MARK: - Public Methods

    /// TXT 레코드 설정
    public func setTXTRecord(_ key: String, value: String) {
        txtRecord[key] = value
    }

    /// 광고 시작
    public func startAdvertising() throws {
        guard !isAdvertising else { return }

        let parameters = NWParameters.tcp
        parameters.allowLocalEndpointReuse = true

        guard let nwPort = NWEndpoint.Port(rawValue: port) else {
            throw NetworkError.connectionFailed(NSError(domain: "BonjourAdvertiser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid port"]))
        }
        listener = try NWListener(using: parameters, on: nwPort)

        // Bonjour 서비스 등록
        listener?.service = NWListener.Service(
            name: serviceName,
            type: serviceType,
            txtRecord: txtRecord
        )

        listener?.stateUpdateHandler = { [weak self] state in
            self?.handleListenerState(state)
        }

        listener?.serviceRegistrationUpdateHandler = { [weak self] change in
            self?.handleServiceRegistration(change)
        }

        listener?.start(queue: queue)
    }

    /// 광고 중지
    public func stopAdvertising() {
        guard isAdvertising else { return }
        listener?.cancel()
        listener = nil
        isAdvertising = false
    }

    // MARK: - Private Methods

    private func handleListenerState(_ state: NWListener.State) {
        switch state {
        case .setup:
            break

        case .waiting(let error):
            logger.debug("Waiting: \(error.localizedDescription)")

        case .ready:
            isAdvertising = true
            if let port = listener?.port {
                logger.info("Advertising '\(self.serviceName)' on port \(port.rawValue)")
            }
            delegate?.bonjourAdvertiserDidStart(self)

        case .failed(let error):
            isAdvertising = false
            delegate?.bonjourAdvertiser(self, didFailWithError: error)

        case .cancelled:
            isAdvertising = false

        @unknown default:
            break
        }
    }

    private func handleServiceRegistration(_ change: NWListener.ServiceRegistrationChange) {
        switch change {
        case .add(let endpoint):
            if case .service(let name, let type, let domain, _) = endpoint {
                logger.info("Registered: \(name).\(type)\(domain)")
            }

        case .remove(let endpoint):
            if case .service(let name, let type, let domain, _) = endpoint {
                logger.info("Unregistered: \(name).\(type)\(domain)")
            }

        @unknown default:
            break
        }
    }
}
