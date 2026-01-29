import Foundation

// MARK: - Widget Data Manager

/// Manages shared data between the main app and widgets
enum WidgetDataManager {
    // App Group identifier for data sharing
    private static let appGroupIdentifier = "group.com.snap.app"

    private static var userDefaults: UserDefaults? {
        UserDefaults(suiteName: appGroupIdentifier)
    }

    // MARK: - Keys

    private static let isConnectedKey = "widget.isConnected"
    private static let deviceNameKey = "widget.deviceName"
    private static let macrosKey = "widget.macros"

    // MARK: - Connection Status

    static var isConnected: Bool {
        userDefaults?.bool(forKey: isConnectedKey) ?? false
    }

    static var connectedDeviceName: String? {
        userDefaults?.string(forKey: deviceNameKey)
    }

    static func updateConnectionStatus(isConnected: Bool, deviceName: String?) {
        userDefaults?.set(isConnected, forKey: isConnectedKey)
        userDefaults?.set(deviceName, forKey: deviceNameKey)
    }

    // MARK: - Macros

    static func loadMacros() -> [WidgetMacroItem] {
        guard let data = userDefaults?.data(forKey: macrosKey),
              let macros = try? JSONDecoder().decode([WidgetMacroItem].self, from: data) else {
            return []
        }
        return macros
    }

    static func saveMacros(_ macros: [WidgetMacroItem]) {
        if let data = try? JSONEncoder().encode(macros) {
            userDefaults?.set(data, forKey: macrosKey)
        }
    }

    // MARK: - Now Playing

    private static let nowPlayingKey = "widget.nowPlaying"

    static func loadNowPlaying() -> WidgetNowPlaying? {
        guard let data = userDefaults?.data(forKey: nowPlayingKey),
              let nowPlaying = try? JSONDecoder().decode(WidgetNowPlaying.self, from: data) else {
            return nil
        }
        return nowPlaying
    }

    static func saveNowPlaying(_ nowPlaying: WidgetNowPlaying?) {
        if let nowPlaying = nowPlaying,
           let data = try? JSONEncoder().encode(nowPlaying) {
            userDefaults?.set(data, forKey: nowPlayingKey)
        } else {
            userDefaults?.removeObject(forKey: nowPlayingKey)
        }
    }
}
