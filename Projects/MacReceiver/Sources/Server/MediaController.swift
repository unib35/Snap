import AppKit
import Foundation
import Shared

/// 미디어 컨트롤러
/// AppleScript 및 시스템 키 이벤트를 사용하여 미디어를 제어합니다.
@MainActor
public final class MediaController {
    public static let shared = MediaController()

    private init() {}

    // MARK: - Public Methods

    /// 미디어 제어 명령 실행
    public func execute(command: MediaControl.Command, volume: Float = 0) {
        switch command {
        case .playPause:
            sendMediaKey(.playPause)
        case .nextTrack:
            sendMediaKey(.next)
        case .prevTrack:
            sendMediaKey(.previous)
        case .volumeUp:
            sendMediaKey(.volumeUp)
        case .volumeDown:
            sendMediaKey(.volumeDown)
        case .mute:
            sendMediaKey(.mute)
        case .setVolume:
            setVolume(level: volume)
        }
    }

    // MARK: - Media Keys

    private enum MediaKey: UInt32 {
        case playPause = 16      // NX_KEYTYPE_PLAY
        case next = 17           // NX_KEYTYPE_NEXT
        case previous = 18       // NX_KEYTYPE_PREVIOUS
        case mute = 7            // NX_KEYTYPE_MUTE
        case volumeUp = 0        // NX_KEYTYPE_SOUND_UP
        case volumeDown = 1      // NX_KEYTYPE_SOUND_DOWN
    }

    private func sendMediaKey(_ key: MediaKey) {
        let keyCode = key.rawValue

        // Key Down
        let keyDownEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xa00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | 0x0a00),
            data2: -1
        )

        // Key Up
        let keyUpEvent = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: 0xb00),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8,
            data1: Int((keyCode << 16) | 0x0b00),
            data2: -1
        )

        if let keyDownCG = keyDownEvent?.cgEvent {
            keyDownCG.post(tap: .cghidEventTap)
        }

        if let keyUpCG = keyUpEvent?.cgEvent {
            keyUpCG.post(tap: .cghidEventTap)
        }
    }

    // MARK: - Volume Control

    /// 볼륨 설정 (0.0 ~ 1.0)
    private func setVolume(level: Float) {
        let clampedLevel = max(0, min(1, level))
        let volumePercent = Int(clampedLevel * 100)

        let script = """
            set volume output volume \(volumePercent)
        """

        runAppleScript(script)
    }

    /// 현재 볼륨 가져오기
    public func getVolume() -> Float {
        let script = """
            output volume of (get volume settings)
        """

        if let result = runAppleScript(script),
           let volume = Float(result) {
            return volume / 100.0
        }
        return 0
    }

    /// 음소거 상태 확인
    public func isMuted() -> Bool {
        let script = """
            output muted of (get volume settings)
        """

        if let result = runAppleScript(script) {
            return result.lowercased() == "true"
        }
        return false
    }

    // MARK: - Now Playing Info

    /// 현재 재생 중인 앱 정보
    public struct NowPlayingInfo: Sendable {
        public let appName: String
        public let title: String
        public let artist: String
        public let album: String
        public let isPlaying: Bool
    }

    /// 현재 재생 정보 가져오기
    public func getNowPlayingInfo() -> NowPlayingInfo? {
        let script = """
            tell application "System Events"
                set frontApp to name of first application process whose frontmost is true
            end tell

            tell application "Music"
                if player state is playing then
                    set trackName to name of current track
                    set trackArtist to artist of current track
                    set trackAlbum to album of current track
                    return "Music|" & trackName & "|" & trackArtist & "|" & trackAlbum & "|true"
                else
                    return ""
                end if
            end tell
        """

        if let result = runAppleScript(script), !result.isEmpty {
            let parts = result.components(separatedBy: "|")
            if parts.count >= 5 {
                return NowPlayingInfo(
                    appName: parts[0],
                    title: parts[1],
                    artist: parts[2],
                    album: parts[3],
                    isPlaying: parts[4] == "true"
                )
            }
        }
        return nil
    }

    // MARK: - AppleScript Helper

    @discardableResult
    private func runAppleScript(_ source: String) -> String? {
        var error: NSDictionary?
        if let script = NSAppleScript(source: source) {
            let output = script.executeAndReturnError(&error)
            if error == nil {
                return output.stringValue
            }
        }
        return nil
    }
}
