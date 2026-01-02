import ComposableArchitecture
import SwiftUI

public struct MediaView: View {
    @Bindable var store: StoreOf<MediaFeature>

    public init(store: StoreOf<MediaFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Now Playing Area (placeholder)
            nowPlayingArea

            Spacer()

            // Playback Controls
            playbackControls

            // Volume Controls
            volumeControls

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
    }

    // MARK: - Now Playing Area

    private var nowPlayingArea: some View {
        VStack(spacing: 16) {
            // Album Art Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.secondarySystemBackground))
                .frame(width: 200, height: 200)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(Color(.tertiaryLabel))
                )
                .accessibilityLabel("앨범 아트")

            VStack(spacing: 8) {
                Text("Not Playing")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(Color(.label))

                Text("Select a track to play")
                    .font(.subheadline)
                    .foregroundStyle(Color(.secondaryLabel))
            }
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Previous Track
            MediaButton(
                icon: "backward.fill",
                size: 28,
                accessibilityLabel: "이전 트랙"
            ) {
                store.send(.previousTrackTapped)
            }

            // Play/Pause
            MediaButton(
                icon: store.isPlaying ? "pause.fill" : "play.fill",
                size: 40,
                isPrimary: true,
                accessibilityLabel: store.isPlaying ? "일시정지" : "재생"
            ) {
                store.send(.playPauseTapped)
            }

            // Next Track
            MediaButton(
                icon: "forward.fill",
                size: 28,
                accessibilityLabel: "다음 트랙"
            ) {
                store.send(.nextTrackTapped)
            }
        }
    }

    // MARK: - Volume Controls

    private var volumeControls: some View {
        VStack(spacing: 16) {
            HStack(spacing: 16) {
                // Volume Down
                Button {
                    store.send(.volumeDownTapped)
                } label: {
                    Image(systemName: "speaker.fill")
                        .font(.callout)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .accessibilityLabel("볼륨 줄이기")

                // Volume Slider
                Slider(
                    value: $store.volume.sending(\.volumeChanged),
                    in: 0...1
                )
                .tint(.accentColor)
                .accessibilityLabel("볼륨")
                .accessibilityValue("\(Int(store.volume * 100))%")

                // Volume Up
                Button {
                    store.send(.volumeUpTapped)
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.callout)
                        .foregroundStyle(Color(.secondaryLabel))
                }
                .accessibilityLabel("볼륨 높이기")
            }
            .padding(.horizontal)

            // Mute Button
            Button {
                store.send(.muteTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.subheadline)

                    Text(store.isMuted ? "Unmute" : "Mute")
                        .font(.subheadline.weight(.medium))
                }
                .foregroundStyle(store.isMuted ? .red : Color(.secondaryLabel))
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(Color(.secondarySystemBackground))
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
            }
            .accessibilityLabel(store.isMuted ? "음소거 해제" : "음소거")
        }
    }
}

// MARK: - Media Button

struct MediaButton: View {
    let icon: String
    let size: CGFloat
    var isPrimary: Bool = false
    var accessibilityLabel: String = ""
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(Color(.label))
                .frame(width: buttonSize, height: buttonSize)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color(.separator), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(accessibilityLabel)
        .pressEvents {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = true
            }
        } onRelease: {
            withAnimation(.spring(response: 0.2, dampingFraction: 0.6)) {
                isPressed = false
            }
        }
    }

    private var buttonSize: CGFloat {
        isPrimary ? 80 : 56
    }

    private var backgroundColor: Color {
        isPrimary ? Color(.tertiarySystemBackground) : Color(.secondarySystemBackground)
    }
}

#Preview {
    MediaView(
        store: Store(initialState: MediaFeature.State()) {
            MediaFeature()
        }
    )
}
