import ComposableArchitecture
@preconcurrency import Foundation
import UIKit

/// 배터리 모니터링 클라이언트
public struct BatteryClient: Sendable {
    public var isLowPowerModeEnabled: @Sendable () -> Bool
    public var observeLowPowerMode: @Sendable () -> AsyncStream<Bool>
}

extension BatteryClient: DependencyKey {
    public static var liveValue: BatteryClient {
        BatteryClient(
            isLowPowerModeEnabled: { ProcessInfo.processInfo.isLowPowerModeEnabled },
            observeLowPowerMode: {
                AsyncStream { continuation in
                    // 초기 상태 전송
                    continuation.yield(ProcessInfo.processInfo.isLowPowerModeEnabled)

                    // 저전력 모드 변경 알림 등록
                    let observer = NotificationCenter.default.addObserver(
                        forName: .NSProcessInfoPowerStateDidChange,
                        object: nil,
                        queue: .main
                    ) { _ in
                        let isLowPower = ProcessInfo.processInfo.isLowPowerModeEnabled
                        continuation.yield(isLowPower)
                    }

                    continuation.onTermination = { @Sendable _ in
                        NotificationCenter.default.removeObserver(observer)
                    }
                }
            }
        )
    }

    public static var testValue: BatteryClient {
        BatteryClient(
            isLowPowerModeEnabled: { false },
            observeLowPowerMode: { .finished }
        )
    }
}

public extension DependencyValues {
    var batteryClient: BatteryClient {
        get { self[BatteryClient.self] }
        set { self[BatteryClient.self] = newValue }
    }
}
