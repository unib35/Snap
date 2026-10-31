import Foundation

// MARK: - Widget Macro Item

/// 위젯에 표시하는 매크로 요약
public struct WidgetMacroItem: Identifiable, Codable, Equatable, Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let colorName: String

    public init(id: UUID, name: String, icon: String, colorName: String) {
        self.id = id
        self.name = name
        self.icon = icon
        self.colorName = colorName
    }

    public init(macro: Macro) {
        self.init(id: macro.id, name: macro.name, icon: macro.icon, colorName: macro.color.rawValue)
    }
}

// MARK: - Widget Now Playing

/// 위젯에 표시하는 재생 정보
public struct WidgetNowPlaying: Codable, Equatable, Sendable {
    public let title: String
    public let artist: String
    public let album: String
    public let isPlaying: Bool
    public let appName: String

    public init(title: String, artist: String, album: String, isPlaying: Bool, appName: String) {
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.appName = appName
    }

    /// 제목이 없으면 재생 중인 항목이 없는 것으로 보고 nil을 반환
    public init?(info: NowPlayingInfo) {
        guard !info.title.isEmpty else { return nil }
        self.init(
            title: info.title,
            artist: info.artist,
            album: info.album,
            isPlaying: info.isPlaying,
            appName: info.appName
        )
    }
}

// MARK: - Widget Data Store

/// 앱과 위젯이 App Group으로 공유하는 데이터 저장소
public struct WidgetDataStore: @unchecked Sendable {
    /// App Group identifier for data sharing
    public static let appGroupIdentifier = "group.com.snap.app"

    public static let shared = WidgetDataStore(
        userDefaults: UserDefaults(suiteName: appGroupIdentifier)
    )

    private let userDefaults: UserDefaults?

    public init(userDefaults: UserDefaults?) {
        self.userDefaults = userDefaults
    }

    // MARK: - Keys

    private static let isConnectedKey = "widget.isConnected"
    private static let deviceNameKey = "widget.deviceName"
    private static let macrosKey = "widget.macros"
    private static let nowPlayingKey = "widget.nowPlaying"

    // MARK: - Connection Status

    public var isConnected: Bool {
        userDefaults?.bool(forKey: Self.isConnectedKey) ?? false
    }

    public var connectedDeviceName: String? {
        userDefaults?.string(forKey: Self.deviceNameKey)
    }

    public func updateConnectionStatus(isConnected: Bool, deviceName: String?) {
        userDefaults?.set(isConnected, forKey: Self.isConnectedKey)
        userDefaults?.set(deviceName, forKey: Self.deviceNameKey)
    }

    // MARK: - Macros

    public func loadMacros() -> [WidgetMacroItem] {
        guard let data = userDefaults?.data(forKey: Self.macrosKey),
              let macros = try? JSONDecoder().decode([WidgetMacroItem].self, from: data) else {
            return []
        }
        return macros
    }

    public func saveMacros(_ macros: [WidgetMacroItem]) {
        if let data = try? JSONEncoder().encode(macros) {
            userDefaults?.set(data, forKey: Self.macrosKey)
        }
    }

    // MARK: - Now Playing

    public func loadNowPlaying() -> WidgetNowPlaying? {
        guard let data = userDefaults?.data(forKey: Self.nowPlayingKey),
              let nowPlaying = try? JSONDecoder().decode(WidgetNowPlaying.self, from: data) else {
            return nil
        }
        return nowPlaying
    }

    public func saveNowPlaying(_ nowPlaying: WidgetNowPlaying?) {
        if let nowPlaying,
           let data = try? JSONEncoder().encode(nowPlaying) {
            userDefaults?.set(data, forKey: Self.nowPlayingKey)
        } else {
            userDefaults?.removeObject(forKey: Self.nowPlayingKey)
        }
    }
}

// MARK: - Widget Kind

/// 앱이 갱신을 요청할 때 쓰는 위젯·컨트롤 종류
public enum WidgetKind {
    public static let quickConnect = "QuickConnectWidget"
    public static let macro = "MacroWidget"
    public static let mediaControl = "MediaControlWidget"
    public static let connectionControl = "com.snap.app.control"
}
