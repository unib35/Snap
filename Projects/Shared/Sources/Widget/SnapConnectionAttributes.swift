#if os(iOS)
import ActivityKit
import Foundation

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
#endif
