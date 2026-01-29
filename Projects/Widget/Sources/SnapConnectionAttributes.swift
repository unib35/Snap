import ActivityKit
import Foundation
import os.log

// MARK: - Logger

private extension Logger {
    static let widget = Logger(subsystem: "com.snap.app.widget", category: "LiveActivity")
}

// MARK: - Snap Connection Attributes

/// Live Activity에 사용되는 Snap 연결 상태 속성
///
/// - `attributes`: 고정 데이터 (앱 정보 등)
/// - `contentState`: 동적 데이터 (연결 상태, 디바이스 이름)
public struct SnapConnectionAttributes: ActivityAttributes {
    // MARK: - Content State

    /// 동적으로 업데이트되는 연결 상태
    public struct ContentState: Codable, Hashable {
        /// 현재 연결 상태
        public var isConnected: Bool

        /// 연결된 Mac 이름
        public var deviceName: String?

        public init(isConnected: Bool = false, deviceName: String? = nil) {
            self.isConnected = isConnected
            self.deviceName = deviceName
        }
    }

    // MARK: - Static Attributes

    /// 앱 이름 (고정)
    public var appName: String = "Snap"

    public init() {}
}

// MARK: - Live Activity Manager

/// Live Activity 생성 및 업데이트를 관리하는 헬퍼
public enum LiveActivityManager {
    // MARK: - Activity ID Storage

    private static let activityIDKey = "snap.liveActivity.id"

    private static var currentActivityID: String? {
        get { UserDefaults.standard.string(forKey: activityIDKey) }
        set { UserDefaults.standard.set(newValue, forKey: activityIDKey) }
    }

    // MARK: - Start Activity

    /// 연결 상태 Live Activity 시작
    @discardableResult
    public static func startConnectionActivity(
        isConnected: Bool,
        deviceName: String?
    ) -> Activity<SnapConnectionAttributes>? {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else {
            return nil
        }

        let attributes = SnapConnectionAttributes()
        let state = SnapConnectionAttributes.ContentState(
            isConnected: isConnected,
            deviceName: deviceName
        )

        do {
            let activity = try Activity.request(
                attributes: attributes,
                content: .init(state: state, staleDate: nil),
                pushType: nil
            )
            currentActivityID = activity.id
            return activity
        } catch {
            Logger.widget.error("Failed to start Live Activity: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Update Activity

    /// 연결 상태 업데이트
    public static func updateConnectionStatus(
        isConnected: Bool,
        deviceName: String?
    ) async {
        let state = SnapConnectionAttributes.ContentState(
            isConnected: isConnected,
            deviceName: deviceName
        )

        // Find existing activity
        for activity in Activity<SnapConnectionAttributes>.activities {
            await activity.update(
                ActivityContent(state: state, staleDate: nil)
            )
        }
    }

    // MARK: - End Activity

    /// 모든 연결 Live Activity 종료
    public static func endAllActivities() async {
        for activity in Activity<SnapConnectionAttributes>.activities {
            await activity.end(nil, dismissalPolicy: .immediate)
        }
        currentActivityID = nil
    }

    /// 연결 해제 상태로 Activity 종료
    public static func endWithDisconnection() async {
        let finalState = SnapConnectionAttributes.ContentState(
            isConnected: false,
            deviceName: nil
        )

        for activity in Activity<SnapConnectionAttributes>.activities {
            await activity.end(
                ActivityContent(state: finalState, staleDate: nil),
                dismissalPolicy: .after(.now + 30) // 30초 후 자동 제거
            )
        }
        currentActivityID = nil
    }

    // MARK: - Check Status

    /// 현재 활성 Live Activity가 있는지 확인
    public static var hasActiveActivity: Bool {
        !Activity<SnapConnectionAttributes>.activities.isEmpty
    }
}
