import ComposableArchitecture
import Foundation
import Network

/// 네트워크 상태 이벤트
public enum NetworkStatusEvent: Equatable, Sendable {
    case connected(NetworkInterface)
    case disconnected
}

/// 네트워크 인터페이스 유형
public enum NetworkInterface: Equatable, Sendable {
    case wifi
    case cellular
    case wiredEthernet
    case other
}

/// TCA 의존성 클라이언트 - 네트워크 상태 모니터링
public struct NetworkMonitorClient: Sendable {
    public var startMonitoring: @Sendable () async -> AsyncStream<NetworkStatusEvent>
    public var stopMonitoring: @Sendable () -> Void
    public var currentStatus: @Sendable () -> NetworkStatusEvent
}

// MARK: - Dependency Key

extension NetworkMonitorClient: DependencyKey {
    public static var liveValue: NetworkMonitorClient {
        let monitor = NetworkMonitor()

        return NetworkMonitorClient(
            startMonitoring: {
                monitor.start()
            },
            stopMonitoring: {
                monitor.stop()
            },
            currentStatus: {
                monitor.currentStatus
            }
        )
    }

    public static var testValue: NetworkMonitorClient {
        NetworkMonitorClient(
            startMonitoring: { .finished },
            stopMonitoring: {},
            currentStatus: { .connected(.wifi) }
        )
    }
}

public extension DependencyValues {
    var networkMonitorClient: NetworkMonitorClient {
        get { self[NetworkMonitorClient.self] }
        set { self[NetworkMonitorClient.self] = newValue }
    }
}

// MARK: - Network Monitor Implementation

private final class NetworkMonitor: @unchecked Sendable {
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "com.snap.network.monitor", qos: .utility)
    private var continuation: AsyncStream<NetworkStatusEvent>.Continuation?
    private var _currentStatus: NetworkStatusEvent = .disconnected
    private let lock = NSLock()

    var currentStatus: NetworkStatusEvent {
        lock.lock()
        defer { lock.unlock() }
        return _currentStatus
    }

    func start() -> AsyncStream<NetworkStatusEvent> {
        AsyncStream { [weak self] continuation in
            self?.continuation = continuation

            self?.monitor.pathUpdateHandler = { [weak self] path in
                guard let self else { return }

                let status: NetworkStatusEvent
                if path.status == .satisfied {
                    let interface = self.determineInterface(path)
                    status = .connected(interface)
                } else {
                    status = .disconnected
                }

                self.lock.lock()
                let previousStatus = self._currentStatus
                self._currentStatus = status
                self.lock.unlock()

                // 상태가 변경된 경우에만 이벤트 발생
                if previousStatus != status {
                    continuation.yield(status)
                }
            }

            self?.monitor.start(queue: self?.queue ?? .main)

            continuation.onTermination = { [weak self] _ in
                self?.stop()
            }
        }
    }

    func stop() {
        monitor.cancel()
        continuation?.finish()
        continuation = nil
    }

    private func determineInterface(_ path: NWPath) -> NetworkInterface {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        } else {
            return .other
        }
    }
}
