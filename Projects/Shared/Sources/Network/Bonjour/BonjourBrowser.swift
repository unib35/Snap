import Foundation
import Network
import os

private let logger = Logger(subsystem: "com.snap.shared", category: "BonjourBrowser")

/// 발견된 서비스 정보
public struct DiscoveredService: Sendable, Equatable, Identifiable {
    public var id: String { "\(name)-\(host):\(port)" }
    public let name: String
    public let host: String
    public let port: UInt16
    public let txtRecord: [String: String]

    public init(name: String, host: String, port: UInt16, txtRecord: [String: String] = [:]) {
        self.name = name
        self.host = host
        self.port = port
        self.txtRecord = txtRecord
    }
}

/// Bonjour 브라우저 델리게이트
public protocol BonjourBrowserDelegate: AnyObject, Sendable {
    func bonjourBrowser(_ browser: BonjourBrowser, didFind service: DiscoveredService)
    func bonjourBrowser(_ browser: BonjourBrowser, didRemove service: DiscoveredService)
    func bonjourBrowser(_ browser: BonjourBrowser, didFailWithError error: Error)
}

/// Bonjour 서비스 브라우저 (iOS에서 macOS 검색)
///
/// - Note: `@unchecked Sendable` - 내부 DispatchQueue(`queue`)를 통해 모든 상태 접근이 직렬화되어 스레드 안전함
public final class BonjourBrowser: @unchecked Sendable {
    // MARK: - Properties

    public weak var delegate: BonjourBrowserDelegate?

    private var browser: NWBrowser?
    private let serviceType: String
    private let queue: DispatchQueue

    public private(set) var isSearching: Bool = false
    public private(set) var discoveredServices: [DiscoveredService] = []

    // MARK: - Initialization

    public init(serviceType: String = NetworkConstants.bonjourServiceTypeTCP) {
        self.serviceType = serviceType
        self.queue = DispatchQueue(label: "com.snap.bonjour.browser", qos: .userInitiated)
    }

    // MARK: - Public Methods

    /// 검색 시작
    public func startSearching() {
        guard !isSearching else { return }

        let descriptor = NWBrowser.Descriptor.bonjour(type: serviceType, domain: "local.")
        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        browser = NWBrowser(for: descriptor, using: parameters)

        browser?.stateUpdateHandler = { [weak self] state in
            self?.handleBrowserState(state)
        }

        browser?.browseResultsChangedHandler = { [weak self] results, changes in
            self?.handleResultsChanged(results: results, changes: changes)
        }

        browser?.start(queue: queue)
        isSearching = true
    }

    /// 검색 중지
    public func stopSearching() {
        guard isSearching else { return }
        browser?.cancel()
        browser = nil
        isSearching = false
        discoveredServices.removeAll()
    }

    // MARK: - Private Methods

    private func handleBrowserState(_ state: NWBrowser.State) {
        switch state {
        case .setup:
            break

        case .ready:
            logger.debug("Ready")

        case .failed(let error):
            isSearching = false
            delegate?.bonjourBrowser(self, didFailWithError: error)

        case .cancelled:
            isSearching = false

        case .waiting(let error):
            logger.debug("Waiting: \(error.localizedDescription)")

        @unknown default:
            break
        }
    }

    private func handleResultsChanged(
        results: Set<NWBrowser.Result>,
        changes: Set<NWBrowser.Result.Change>
    ) {
        for change in changes {
            switch change {
            case .added(let result):
                resolveService(result)

            case .removed(let result):
                removeService(result)

            case .changed(old: _, new: let result, flags: _):
                resolveService(result)

            case .identical:
                break

            @unknown default:
                break
            }
        }
    }

    private func resolveService(_ result: NWBrowser.Result) {
        guard case .service(let name, _, _, _) = result.endpoint else {
            return
        }

        let parameters = NWParameters()
        parameters.includePeerToPeer = true

        let connection = NWConnection(to: result.endpoint, using: parameters)

        connection.stateUpdateHandler = { [weak self, weak connection] state in
            guard let self else { return }

            switch state {
            case .ready:
                if let path = connection?.currentPath,
                   let endpoint = path.remoteEndpoint,
                   case .hostPort(let host, let port) = endpoint {
                    var txtRecord: [String: String] = [:]
                    if case .bonjour(let record) = result.metadata {
                        txtRecord = self.parseTXTRecord(record)
                    }

                    let service = DiscoveredService(
                        name: name,
                        host: host.debugDescription,
                        port: port.rawValue,
                        txtRecord: txtRecord
                    )

                    if !self.discoveredServices.contains(service) {
                        self.discoveredServices.append(service)
                        self.delegate?.bonjourBrowser(self, didFind: service)
                    }
                }
                connection?.cancel()

            case .failed, .cancelled:
                connection?.cancel()

            default:
                break
            }
        }

        connection.start(queue: queue)
    }

    private func removeService(_ result: NWBrowser.Result) {
        guard case .service(let name, _, _, _) = result.endpoint else {
            return
        }

        if let index = discoveredServices.firstIndex(where: { $0.name == name }) {
            let removed = discoveredServices.remove(at: index)
            delegate?.bonjourBrowser(self, didRemove: removed)
        }
    }

    private func parseTXTRecord(_ record: NWTXTRecord) -> [String: String] {
        var result: [String: String] = [:]

        record.dictionary.forEach { key, value in
            result[key] = value
        }

        return result
    }
}
