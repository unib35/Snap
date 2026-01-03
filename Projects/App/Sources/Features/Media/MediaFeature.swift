import ComposableArchitecture
import Shared

@Reducer
public struct MediaFeature {
    @ObservableState
    public struct State: Equatable {
        public var nowPlayingInfo: NowPlayingInfo = .init()
        public var isPlaying: Bool = false
        public var volume: Float = 0.5
        public var isMuted: Bool = false

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        // Playback Controls
        case playPauseTapped
        case nextTrackTapped
        case previousTrackTapped

        // Volume Controls
        case volumeUpTapped
        case volumeDownTapped
        case muteTapped
        case volumeChanged(Float)

        // State Updates
        case setIsPlaying(Bool)
        case nowPlayingInfoReceived(NowPlayingInfo)
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .playPauseTapped:
                state.isPlaying.toggle()
                return .run { _ in
                    await client.sendMediaControl(.playPause, 0)
                }

            case .nextTrackTapped:
                return .run { _ in
                    await client.sendMediaControl(.nextTrack, 0)
                }

            case .previousTrackTapped:
                return .run { _ in
                    await client.sendMediaControl(.prevTrack, 0)
                }

            case .volumeUpTapped:
                state.volume = min(1.0, state.volume + 0.1)
                if state.isMuted {
                    state.isMuted = false
                }
                return .run { [volume = state.volume] _ in
                    await client.sendMediaControl(.volumeUp, volume)
                }

            case .volumeDownTapped:
                state.volume = max(0.0, state.volume - 0.1)
                return .run { [volume = state.volume] _ in
                    await client.sendMediaControl(.volumeDown, volume)
                }

            case .muteTapped:
                state.isMuted.toggle()
                return .run { _ in
                    await client.sendMediaControl(.mute, 0)
                }

            case .volumeChanged(let volume):
                state.volume = volume
                if state.isMuted && volume > 0 {
                    state.isMuted = false
                }
                return .run { _ in
                    await client.sendMediaControl(.setVolume, volume)
                }

            case .setIsPlaying(let isPlaying):
                state.isPlaying = isPlaying
                return .none

            case .nowPlayingInfoReceived(let info):
                state.nowPlayingInfo = info
                state.isPlaying = info.isPlaying
                return .none
            }
        }
    }
}
