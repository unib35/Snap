import Foundation

// MARK: - MediaControl

/// 미디어 제어
public struct MediaControl: Codable, Sendable, Equatable {
    public enum Command: Int, Codable, Sendable, CaseIterable {
        case playPause = 0
        case nextTrack = 1
        case prevTrack = 2
        case volumeUp = 3
        case volumeDown = 4
        case mute = 5
        case setVolume = 6
    }

    public var command: Command
    public var volume: Float

    public init(command: Command = .playPause, volume: Float = 0) {
        self.command = command
        self.volume = volume
    }
}

// MARK: - WindowSnap

/// 윈도우 스냅
public struct WindowSnap: Codable, Sendable, Equatable {
    public enum Position: Int, Codable, Sendable, CaseIterable {
        case leftHalf = 0
        case rightHalf = 1
        case topHalf = 2
        case bottomHalf = 3
        case fullScreen = 4
        case center = 5
        case topLeft = 6
        case topRight = 7
        case bottomLeft = 8
        case bottomRight = 9
    }

    public var position: Position

    public init(position: Position = .leftHalf) {
        self.position = position
    }
}

// MARK: - Presentation

/// 발표 제어
public struct Presentation: Codable, Sendable, Equatable {
    public enum Command: Int, Codable, Sendable, CaseIterable {
        case nextSlide = 0
        case prevSlide = 1
        case start = 2
        case end = 3
        case blankScreen = 4
    }

    public var command: Command

    public init(command: Command = .nextSlide) {
        self.command = command
    }
}

// MARK: - VoiceText

/// 음성 텍스트
public struct VoiceText: Codable, Sendable, Equatable {
    public var text: String
    public var isFinal: Bool

    public init(text: String = "", isFinal: Bool = false) {
        self.text = text
        self.isFinal = isFinal
    }
}

// MARK: - SiriCommand

/// Siri 호출 제어
public struct SiriCommand: Codable, Sendable, Equatable {
    public enum Action: Int, Codable, Sendable, CaseIterable {
        case activate = 0     // Siri 활성화
        case deactivate = 1   // Siri 비활성화
        case dictation = 2    // 받아쓰기 모드
    }

    public var action: Action
    public var text: String   // dictation 모드에서 전달할 텍스트

    public init(action: Action = .activate, text: String = "") {
        self.action = action
        self.text = text
    }
}

// MARK: - ShortsCommand

/// 숏폼 리모컨 명령
public struct ShortsCommand: Codable, Sendable, Equatable {
    public enum Platform: Int, Codable, Sendable, CaseIterable {
        case youtube = 0
        case instagram = 1
        case tiktok = 2
    }

    public enum Action: Int, Codable, Sendable, CaseIterable {
        case nextVideo = 0
        case previousVideo = 1
        case playPause = 2
        case mute = 3
        case like = 4
        case comment = 5
        case share = 6
        case seekForward = 7
        case seekBackward = 8
    }

    public var platform: Platform
    public var action: Action

    public init(platform: Platform = .youtube, action: Action = .nextVideo) {
        self.platform = platform
        self.action = action
    }
}

// MARK: - NowPlayingInfo

/// 현재 재생 중인 미디어 정보 (macOS → iOS)
public struct NowPlayingInfo: Codable, Sendable, Equatable {
    /// 재생 중인 앱 이름 (Music, Spotify 등)
    public var appName: String
    /// 트랙 제목
    public var title: String
    /// 아티스트명
    public var artist: String
    /// 앨범명
    public var album: String
    /// 재생 상태
    public var isPlaying: Bool
    /// 앨범 아트 (JPEG/PNG 데이터, Base64 인코딩)
    public var artworkData: Data?

    public init(
        appName: String = "",
        title: String = "",
        artist: String = "",
        album: String = "",
        isPlaying: Bool = false,
        artworkData: Data? = nil
    ) {
        self.appName = appName
        self.title = title
        self.artist = artist
        self.album = album
        self.isPlaying = isPlaying
        self.artworkData = artworkData
    }

    /// 재생 정보가 비어있는지 확인
    public var isEmpty: Bool {
        title.isEmpty && artist.isEmpty
    }
}
