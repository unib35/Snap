import Foundation
import Shared

// MARK: - Packet Batcher

/// 고빈도 패킷(마우스, 스크롤)을 일괄 처리하여 네트워크 오버헤드 감소
@MainActor
public final class PacketBatcher {
    // MARK: - Types

    public struct BatchedMouseMove: Sendable {
        public var deltaX: Float = 0
        public var deltaY: Float = 0
        public private(set) var hasData: Bool = false

        public mutating func add(deltaX: Float, deltaY: Float) {
            self.deltaX += deltaX
            self.deltaY += deltaY
            self.hasData = true
        }

        public mutating func reset() {
            deltaX = 0
            deltaY = 0
            hasData = false
        }
    }

    public struct BatchedScroll: Sendable {
        public var deltaX: Float = 0
        public var deltaY: Float = 0
        public private(set) var hasData: Bool = false

        public mutating func add(deltaX: Float, deltaY: Float) {
            self.deltaX += deltaX
            self.deltaY += deltaY
            self.hasData = true
        }

        public mutating func reset() {
            deltaX = 0
            deltaY = 0
            hasData = false
        }
    }

    // MARK: - Configuration

    /// 배칭 간격 (기본 16ms = 60fps)
    public var batchInterval: TimeInterval = 0.016

    /// 배칭 활성화 여부
    public var isEnabled: Bool = true

    // MARK: - Properties

    private var mouseMoveBuffer = BatchedMouseMove()
    private var scrollBuffer = BatchedScroll()

    private var flushTimer: Timer?

    private var onMouseMoveFlush: ((Float, Float) -> Void)?
    private var onScrollFlush: ((Float, Float) -> Void)?

    // MARK: - Initialization

    public init() {}

    // MARK: - Public Methods

    /// 배칭 시작
    public func start(
        onMouseMoveFlush: @escaping (Float, Float) -> Void,
        onScrollFlush: @escaping (Float, Float) -> Void
    ) {
        self.onMouseMoveFlush = onMouseMoveFlush
        self.onScrollFlush = onScrollFlush

        flushTimer?.invalidate()
        flushTimer = Timer.scheduledTimer(withTimeInterval: batchInterval, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.flush()
            }
        }
    }

    /// 배칭 중지
    public func stop() {
        flushTimer?.invalidate()
        flushTimer = nil
        onMouseMoveFlush = nil
        onScrollFlush = nil

        mouseMoveBuffer.reset()
        scrollBuffer.reset()
    }

    /// 마우스 이동 추가
    public func addMouseMove(deltaX: Float, deltaY: Float) {
        guard isEnabled else {
            onMouseMoveFlush?(deltaX, deltaY)
            return
        }
        mouseMoveBuffer.add(deltaX: deltaX, deltaY: deltaY)
    }

    /// 스크롤 추가
    public func addScroll(deltaX: Float, deltaY: Float) {
        guard isEnabled else {
            onScrollFlush?(deltaX, deltaY)
            return
        }
        scrollBuffer.add(deltaX: deltaX, deltaY: deltaY)
    }

    // MARK: - Private Methods

    /// 누적된 데이터 전송
    private func flush() {
        // 마우스 이동 전송
        if mouseMoveBuffer.hasData {
            onMouseMoveFlush?(mouseMoveBuffer.deltaX, mouseMoveBuffer.deltaY)
            mouseMoveBuffer.reset()
        }

        // 스크롤 전송
        if scrollBuffer.hasData {
            onScrollFlush?(scrollBuffer.deltaX, scrollBuffer.deltaY)
            scrollBuffer.reset()
        }
    }
}
