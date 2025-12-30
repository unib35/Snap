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
        .background(Color.black)
    }

    // MARK: - Now Playing Area

    private var nowPlayingArea: some View {
        VStack(spacing: 16) {
            // Album Art Placeholder
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.1))
                .frame(width: 200, height: 200)
                .overlay(
                    Image(systemName: "music.note")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.white.opacity(0.3))
                )

            VStack(spacing: 4) {
                Text("Not Playing")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)

                Text("Select a track to play")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.white.opacity(0.6))
            }
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 40) {
            // Previous Track
            MediaButton(
                icon: "backward.fill",
                size: 28
            ) {
                store.send(.previousTrackTapped)
            }

            // Play/Pause
            MediaButton(
                icon: store.isPlaying ? "pause.fill" : "play.fill",
                size: 40,
                isPrimary: true
            ) {
                store.send(.playPauseTapped)
            }

            // Next Track
            MediaButton(
                icon: "forward.fill",
                size: 28
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
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.7))
                }

                // Volume Slider
                Slider(
                    value: $store.volume.sending(\.volumeChanged),
                    in: 0...1
                )
                .tint(.white)

                // Volume Up
                Button {
                    store.send(.volumeUpTapped)
                } label: {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(Color.white.opacity(0.7))
                }
            }
            .padding(.horizontal)

            // Mute Button
            Button {
                store.send(.muteTapped)
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: store.isMuted ? "speaker.slash.fill" : "speaker.wave.2.fill")
                        .font(.system(size: 14))

                    Text(store.isMuted ? "Unmute" : "Mute")
                        .font(.system(size: 14, weight: .medium))
                }
                .foregroundStyle(store.isMuted ? .red : Color.white.opacity(0.7))
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.white.opacity(0.1))
                .clipShape(Capsule())
            }
        }
    }
}

// MARK: - Media Button

struct MediaButton: View {
    let icon: String
    let size: CGFloat
    var isPrimary: Bool = false
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(.white)
                .frame(width: buttonSize, height: buttonSize)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(Color.white.opacity(0.15), lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
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
        isPrimary ? Color.white.opacity(0.2) : Color.white.opacity(0.1)
    }
}

#Preview {
    MediaView(
        store: Store(initialState: MediaFeature.State()) {
            MediaFeature()
        }
    )
    .preferredColorScheme(.dark)
}
