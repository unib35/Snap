import ComposableArchitecture
import Foundation
import SwiftUI

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

        var color: Color {
            switch self {
            case .youtube: return .red
            case .instagram: return .pink
            case .tiktok: return .primary
            }
        }
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var isActive: Bool = false
        public var selectedPlatform: Platform = .youtube
        public var isMuted: Bool = false
        public var isPaused: Bool = false
        public var isLiked: Bool = false

        // Auto scroll
        public var isAutoScrollEnabled: Bool = false
        public var autoScrollInterval: Int = 10  // seconds

        public init() {}
    }

    // MARK: - Action

    public enum Action: Equatable, Sendable {
        // Mode
        case start
        case stop

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

        // Interaction
        case toggleLike

        // Auto Scroll
        case toggleAutoScroll
        case setAutoScrollInterval(Int)
        case autoScrollTick
    }

    // MARK: - Dependencies

    @Dependency(\.connectionClient) var connectionClient
    @Dependency(\.continuousClock) var clock

    public init() {}

    // MARK: - Cancel ID

    private enum CancelID {
        case autoScroll
    }

    // MARK: - Key Codes

    private enum KeyCode {
        static let upArrow: UInt32 = 126
        static let downArrow: UInt32 = 125
        static let leftArrow: UInt32 = 123
        static let rightArrow: UInt32 = 124
        static let space: UInt32 = 49
        static let mKey: UInt32 = 46
        static let lKey: UInt32 = 37  // YouTube like
        static let kKey: UInt32 = 40  // YouTube prev
        static let jKey: UInt32 = 38  // YouTube next
    }

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .start:
                state.isActive = true
                state.isPaused = false
                state.isMuted = false
                state.isLiked = false
                return .none

            case .stop:
                state.isActive = false
                return .none

            case .platformSelected(let platform):
                state.selectedPlatform = platform
                return .none

            case .nextVideo:
                state.isLiked = false  // Reset like state for new video
                // All platforms use down arrow for next video in fullscreen/shorts mode
                return .run { [connectionClient] _ in
                    await connectionClient.sendKeyEvent(KeyCode.downArrow, .press, 0)
                }

            case .previousVideo:
                // All platforms use up arrow for previous video
                return .run { [connectionClient] _ in
                    await connectionClient.sendKeyEvent(KeyCode.upArrow, .press, 0)
                }

            case .togglePlayPause:
                state.isPaused.toggle()
                return .run { [connectionClient] _ in
                    // Space to toggle play/pause
                    await connectionClient.sendKeyEvent(KeyCode.space, .press, 0)
                }

            case .toggleMute:
                state.isMuted.toggle()
                return .run { [connectionClient] _ in
                    // M key to toggle mute
                    await connectionClient.sendKeyEvent(KeyCode.mKey, .press, 0)
                }

            case .seekForward:
                return .run { [connectionClient] _ in
                    await connectionClient.sendKeyEvent(KeyCode.rightArrow, .press, 0)
                }

            case .seekBackward:
                return .run { [connectionClient] _ in
                    await connectionClient.sendKeyEvent(KeyCode.leftArrow, .press, 0)
                }

            case .toggleLike:
                state.isLiked.toggle()
                return .run { [connectionClient] _ in
                    // L key to like on YouTube
                    await connectionClient.sendKeyEvent(KeyCode.lKey, .press, 0)
                }

            case .toggleAutoScroll:
                state.isAutoScrollEnabled.toggle()
                if state.isAutoScrollEnabled {
                    return .run { [clock] send in
                        for await _ in clock.timer(interval: .seconds(1)) {
                            await send(.autoScrollTick)
                        }
                    }
                    .cancellable(id: CancelID.autoScroll)
                } else {
                    return .cancel(id: CancelID.autoScroll)
                }

            case .setAutoScrollInterval(let interval):
                state.autoScrollInterval = max(3, min(60, interval))
                return .none

            case .autoScrollTick:
                guard state.isAutoScrollEnabled, !state.isPaused else { return .none }
                // Use modulo to check if it's time to scroll
                // This is tracked externally in the view with a countdown
                return .none
            }
        }
    }
}
