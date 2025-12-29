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
