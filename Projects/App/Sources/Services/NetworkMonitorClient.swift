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

final class NetworkMonitor: @unchecked Sendable {
    private var monitor: NWPathMonitor?
    private var generation: UUID?
    private let queue = DispatchQueue(label: "com.snap.network.monitor", qos: .utility)
    private var continuation: AsyncStream<NetworkStatusEvent>.Continuation?
    private var storedStatus: NetworkStatusEvent = .disconnected
    private let lock = NSRecursiveLock()

    var currentStatus: NetworkStatusEvent { lock.withLock { storedStatus } }

    func start() -> AsyncStream<NetworkStatusEvent> {
        lock.withLock {
            stop()
            let id = UUID()
            generation = id
            let monitor = NWPathMonitor()
            self.monitor = monitor
            return AsyncStream { continuation in
                self.continuation = continuation
                continuation.yield(storedStatus)
                monitor.pathUpdateHandler = { [weak self] path in
                    guard let self else { return }
                    self.lock.withLock {
                        guard self.generation == id else { return }
                        let status: NetworkStatusEvent = path.status == .satisfied
                            ? .connected(self.determineInterface(path)) : .disconnected
                        self.storedStatus = status
                        self.continuation?.yield(status)
                    }
                }
                continuation.onTermination = { [weak self] _ in self?.stop(generation: id) }
                monitor.start(queue: queue)
            }
        }
    }

    func stop() {
        lock.withLock {
            let oldMonitor = monitor
            let oldContinuation = continuation
            generation = nil
            monitor = nil
            continuation = nil
            oldMonitor?.cancel()
            oldContinuation?.finish()
        }
    }

    private func stop(generation id: UUID) {
        lock.withLock {
            guard generation == id else { return }
            stop()
        }
    }

    private func determineInterface(_ path: NWPath) -> NetworkInterface {
        if path.usesInterfaceType(.wifi) { return .wifi }
        if path.usesInterfaceType(.cellular) { return .cellular }
        if path.usesInterfaceType(.wiredEthernet) { return .wiredEthernet }
        return .other
    }
}
