import ComposableArchitecture
import Foundation
import Shared
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

        /// ShortsCommand.Platform으로 변환
        var commandPlatform: ShortsCommand.Platform {
            switch self {
            case .youtube: return .youtube
            case .instagram: return .instagram
            case .tiktok: return .tiktok
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
        case openComment
        case openShare

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
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .nextVideo)
                }

            case .previousVideo:
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .previousVideo)
                }

            case .togglePlayPause:
                state.isPaused.toggle()
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .playPause)
                }

            case .toggleMute:
                state.isMuted.toggle()
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .mute)
                }

            case .seekForward:
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .seekForward)
                }

            case .seekBackward:
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .seekBackward)
                }

            case .toggleLike:
                state.isLiked.toggle()
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .like)
                }

            case .openComment:
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .comment)
                }

            case .openShare:
                let platform = state.selectedPlatform.commandPlatform
                return .run { [connectionClient] _ in
                    await connectionClient.sendShortsCommand(platform, .share)
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
