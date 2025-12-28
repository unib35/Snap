import Foundation

// MARK: - AppListRequest

/// 앱 목록 요청 (iOS → Mac)
public struct AppListRequest: Codable, Sendable, Equatable {
    public init() {}
}

// MARK: - AppInfo

/// 앱 정보
public struct AppInfo: Codable, Sendable, Equatable {
    public var bundleID: String
    public var name: String
    public var iconData: Data
    public var isActive: Bool
    public var pid: UInt32

    public init(
        bundleID: String = "",
        name: String = "",
        iconData: Data = Data(),
        isActive: Bool = false,
        pid: UInt32 = 0
    ) {
        self.bundleID = bundleID
        self.name = name
        self.iconData = iconData
        self.isActive = isActive
        self.pid = pid
    }
}

// MARK: - AppListResponse

/// 앱 목록 응답 (Mac → iOS)
public struct AppListResponse: Codable, Sendable, Equatable {
    public var apps: [AppInfo]

    public init(apps: [AppInfo] = []) {
        self.apps = apps
    }
}

// MARK: - AppFocus

/// 앱 포커스 전환 (iOS → Mac)
public struct AppFocus: Codable, Sendable, Equatable {
    public var bundleID: String
    public var pid: UInt32

    public init(bundleID: String = "", pid: UInt32 = 0) {
        self.bundleID = bundleID
        self.pid = pid
    }
}
