import ComposableArchitecture
import Foundation

@Reducer
public struct ShortsRemoteFeature {
    // MARK: - Platform

    public enum Platform: String, CaseIterable, Sendable {
        case youtube = "YouTube"
        case instagram = "Instagram"
        case tiktok = "TikTok"

        var icon: String {
            switch self {
            case .youtube: return "play.rectangle.fill"
            case .instagram: return "camera.circle.fill"
            case .tiktok: return "music.note"
            }
        }
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var selectedPlatform: Platform = .youtube
        public var isMuted: Bool = false
        public var isPaused: Bool = false

        public init() {}
    }

    // MARK: - Action

    public enum Action: Equatable, Sendable {
        // Platform
        case platformSelected(Platform)

        // Navigation
        case nextVideo
        case previousVideo

        // Playback
        case togglePlayPause
        case toggleMute
        case seekForward
        case seekBackward

        // Haptic
        case triggerHaptic
    }

    // MARK: - Dependencies

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    // MARK: - Key Codes

    private enum KeyCode {
        static let upArrow: UInt32 = 126
        static let downArrow: UInt32 = 125
        static let leftArrow: UInt32 = 123
        static let rightArrow: UInt32 = 124
        static let space: UInt32 = 49
        static let mKey: UInt32 = 46
        static let kKey: UInt32 = 40  // YouTube prev
        static let jKey: UInt32 = 38  // YouTube next
    }

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .platformSelected(let platform):
                state.selectedPlatform = platform
                return .none

            case .nextVideo:
                // All platforms use down arrow for next video in fullscreen/shorts mode
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.downArrow, .press, 0)
                    await send(.triggerHaptic)
                }

            case .previousVideo:
                // All platforms use up arrow for previous video
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.upArrow, .press, 0)
                    await send(.triggerHaptic)
                }

            case .togglePlayPause:
                state.isPaused.toggle()
                return .run { [connectionClient] send in
                    // Space to toggle play/pause
                    await connectionClient.sendKeyEvent(KeyCode.space, .press, 0)
                    await send(.triggerHaptic)
                }

            case .toggleMute:
                state.isMuted.toggle()
                return .run { [connectionClient] send in
                    // M key to toggle mute
                    await connectionClient.sendKeyEvent(KeyCode.mKey, .press, 0)
                    await send(.triggerHaptic)
                }

            case .seekForward:
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.rightArrow, .press, 0)
                    await send(.triggerHaptic)
                }

            case .seekBackward:
                return .run { [connectionClient] send in
                    await connectionClient.sendKeyEvent(KeyCode.leftArrow, .press, 0)
                    await send(.triggerHaptic)
                }

            case .triggerHaptic:
                // Haptic feedback is handled in the View
                return .none
            }
        }
    }
}
