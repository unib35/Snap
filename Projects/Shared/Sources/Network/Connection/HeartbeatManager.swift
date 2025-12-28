import Foundation

/// 하트비트 매니저 델리게이트
public protocol HeartbeatManagerDelegate: AnyObject, Sendable {
    func heartbeatManagerDidTimeout(_ manager: HeartbeatManager)
    func heartbeatManager(_ manager: HeartbeatManager, shouldSendHeartbeat: @escaping () -> Void)
}

/// 하트비트 관리자
public final class HeartbeatManager: @unchecked Sendable {
    // MARK: - Constants

    /// TCP 하트비트 간격 (5초)
    public static let tcpInterval: TimeInterval = 5.0

    /// UDP 하트비트 간격 (1초)
    public static let udpInterval: TimeInterval = 1.0

    /// 타임아웃 (15초)
    public static let timeout: TimeInterval = 15.0

    // MARK: - Properties

    public weak var delegate: HeartbeatManagerDelegate?

    private let interval: TimeInterval
    private let timeout: TimeInterval

    private var sendTimer: DispatchSourceTimer?
    private var timeoutTimer: DispatchSourceTimer?
    private let queue: DispatchQueue

    private var lastReceivedTime: Date = Date()
    private var isRunning: Bool = false

    // MARK: - Initialization

    public init(
        interval: TimeInterval = HeartbeatManager.tcpInterval,
        timeout: TimeInterval = HeartbeatManager.timeout
    ) {
        self.interval = interval
        self.timeout = timeout
        self.queue = DispatchQueue(label: "com.snap.heartbeat", qos: .utility)
    }

    // MARK: - Public Methods

    /// 하트비트 시작
    public func start() {
        guard !isRunning else { return }
        isRunning = true
        lastReceivedTime = Date()

        setupSendTimer()
        setupTimeoutTimer()
    }

    /// 하트비트 중지
    public func stop() {
        guard isRunning else { return }
        isRunning = false

        sendTimer?.cancel()
        sendTimer = nil

        timeoutTimer?.cancel()
        timeoutTimer = nil
    }

    /// 하트비트 수신 시 호출
    public func didReceiveHeartbeat() {
        lastReceivedTime = Date()
    }

    /// 아무 메시지 수신 시 호출 (타임아웃 리셋)
    public func didReceiveMessage() {
        lastReceivedTime = Date()
    }

    // MARK: - Private Methods

    private func setupSendTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + interval, repeating: interval)

        timer.setEventHandler { [weak self] in
            guard let self, self.isRunning else { return }
            self.delegate?.heartbeatManager(self) {
                // 하트비트 전송 콜백
            }
        }

        timer.resume()
        sendTimer = timer
    }

    private func setupTimeoutTimer() {
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 1.0, repeating: 1.0)

        timer.setEventHandler { [weak self] in
            guard let self, self.isRunning else { return }

            let elapsed = Date().timeIntervalSince(self.lastReceivedTime)
            if elapsed > self.timeout {
                self.stop()
                self.delegate?.heartbeatManagerDidTimeout(self)
            }
        }

        timer.resume()
        timeoutTimer = timer
    }

    // MARK: - Helper

    /// 현재 타임스탬프 생성
    public static func currentTimestamp() -> UInt64 {
        UInt64(Date().timeIntervalSince1970 * 1_000_000)
    }

    /// 하트비트 메시지 생성
    public static func createHeartbeat() -> Heartbeat {
        Heartbeat(timestamp: currentTimestamp())
    }
}
