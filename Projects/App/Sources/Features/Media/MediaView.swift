import ComposableArchitecture
import SwiftUI

public struct MediaView: View {
    @Bindable var store: StoreOf<MediaFeature>
    @StateObject private var volumeHandler = VolumeButtonHandler()
    @Environment(\.layoutMode) private var layoutMode

    public init(store: StoreOf<MediaFeature>) {
        self.store = store
    }

    private var contentSpacing: CGFloat {
        layoutMode == .compact ? 20 : 32
    }

    public var body: some View {
        iPadOptimizedContainer {
            VStack(spacing: contentSpacing) {
                Spacer()

                // Now Playing Area (placeholder)
                nowPlayingArea

                Spacer()

                // Playback Controls
                playbackControls

                // Volume Controls
                volumeControls

                // Hardware Volume Toggle
                hardwareVolumeToggle

                Spacer()
            }
            .padding(layoutMode == .compact ? SnapSpacing.md : SnapSpacing.lg)
        }
        .background(SnapColors.systemBackground)
        .onAppear {
            if store.isHardwareVolumeControlEnabled {
                setupVolumeHandler()
            }
        }
        .onDisappear {
            volumeHandler.stop()
        }
        .onChange(of: store.isHardwareVolumeControlEnabled) { _, isEnabled in
            if isEnabled {
                setupVolumeHandler()
            } else {
                volumeHandler.stop()
            }
        }
    }

    private func setupVolumeHandler() {
        volumeHandler.onVolumeUp = { [store] in
            store.send(.hardwareVolumeUp)
        }
        volumeHandler.onVolumeDown = { [store] in
            store.send(.hardwareVolumeDown)
        }
        volumeHandler.start()
    }

    // MARK: - Now Playing Area

    private var albumArtSize: CGFloat {
        layoutMode == .compact ? 160 : 200
    }

    private var nowPlayingArea: some View {
        VStack(spacing: layoutMode == .compact ? 12 : 16) {
            // Album Art
            albumArtView
                .accessibilityLabel("앨범 아트")

            // Track Info
            trackInfoView
        }
        .animation(.easeInOut(duration: 0.3), value: store.nowPlayingInfo)
    }

    @ViewBuilder
    private var albumArtView: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(SnapColors.secondarySystemBackground)

            if let artworkData = store.nowPlayingInfo.artworkData,
               let uiImage = UIImage(data: artworkData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
            } else {
                Image(systemName: appIcon)
                    .font(.largeTitle)
                    .imageScale(.large)
                    .foregroundStyle(appIconColor)
            }
        }
        .frame(width: albumArtSize, height: albumArtSize)
        .shadow(color: .black.opacity(0.1), radius: 10, y: 5)
    }

    private var appIcon: String {
        switch store.nowPlayingInfo.appName.lowercased() {
        case "music":
            return "music.note"
        case "spotify":
            return "waveform"
        default:
            return store.nowPlayingInfo.isEmpty ? "music.note" : "play.circle"
        }
    }

    private var appIconColor: Color {
        switch store.nowPlayingInfo.appName.lowercased() {
        case "music":
            return .pink
        case "spotify":
            return .green
        default:
            return SnapColors.tertiaryLabel
        }
    }

    @ViewBuilder
    private var trackInfoView: some View {
        if store.nowPlayingInfo.isEmpty {
            // Not Playing
            VStack(spacing: 8) {
                Text("Not Playing")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SnapColors.label)

                Text("Play music on your Mac")
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.secondaryLabel)
            }
        } else {
            // Now Playing Info
            VStack(spacing: 6) {
                // App Badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(store.isPlaying ? .green : .orange)
                        .frame(width: 6, height: 6)

                    Text(store.nowPlayingInfo.appName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(SnapColors.secondaryLabel)
                }

                // Track Title
                Text(store.nowPlayingInfo.title)
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(SnapColors.label)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Artist
                Text(store.nowPlayingInfo.artist)
                    .font(.subheadline)
                    .foregroundStyle(SnapColors.secondaryLabel)
                    .lineLimit(1)
                    .truncationMode(.tail)

                // Album (if available)
                if !store.nowPlayingInfo.album.isEmpty {
                    Text(store.nowPlayingInfo.album)
                        .font(.caption)
                        .foregroundStyle(SnapColors.tertiaryLabel)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .frame(maxWidth: 240)
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: layoutMode == .compact ? 32 : 40) {
            // Previous Track
            MediaButton(
                icon: "backward.fill",
                size: layoutMode == .compact ? 24 : 28,
                isCompact: layoutMode == .compact,
                accessibilityLabel: "이전 트랙"
            ) {
                store.send(.previousTrackTapped)
            }

            // Play/Pause
            MediaButton(
                icon: store.isPlaying ? "pause.fill" : "play.fill",
                size: layoutMode == .compact ? 34 : 40,
                isCompact: layoutMode == .compact,
                isPrimary: true,
                accessibilityLabel: store.isPlaying ? "일시정지" : "재생"
            ) {
                store.send(.playPauseTapped)
            }

            // Next Track
            MediaButton(
                icon: "forward.fill",
                size: layoutMode == .compact ? 24 : 28,
                isCompact: layoutMode == .compact,
                accessibilityLabel: "다음 트랙"
            ) {
                store.send(.nextTrackTapped)
            }
        }
    }

    // MARK: - Volume Controls

    private var volumeControls: some View {
        VStack(spacing: layoutMode == .compact ? 12 : 16) {
            HStack(spacing: layoutMode == .compact ? 12 : 16) {
                // Volume Down
                Button {
                    store.send(.volumeDownTapped)
                } label: {
                    Image(systemName: "speaker.fill")
                        .font(.callout)
                        .foregroundStyle(SnapColors.secondaryLabel)
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
                        .foregroundStyle(SnapColors.secondaryLabel)
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
                .foregroundStyle(store.isMuted ? .red : SnapColors.secondaryLabel)
                .padding(.horizontal, 24)
                .padding(.vertical, 12)
                .background(SnapColors.secondarySystemBackground)
                .clipShape(Capsule())
                .overlay(
                    Capsule()
                        .strokeBorder(SnapColors.separator, lineWidth: 1)
                )
            }
            .accessibilityLabel(store.isMuted ? "음소거 해제" : "음소거")
        }
    }

    // MARK: - Hardware Volume Toggle

    private var hardwareVolumeToggle: some View {
        Toggle(isOn: $store.isHardwareVolumeControlEnabled.sending(\.setHardwareVolumeControlEnabled)) {
            HStack(spacing: 12) {
                Image(systemName: "iphone.radiowaves.left.and.right")
                    .font(.body)
                    .foregroundStyle(SnapColors.secondaryLabel)
                    .frame(width: 24)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Hardware Volume Buttons")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SnapColors.label)

                    Text("Use iPhone volume buttons to control Mac")
                        .font(.caption)
                        .foregroundStyle(SnapColors.tertiaryLabel)
                }
            }
        }
        .toggleStyle(.switch)
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(SnapColors.secondarySystemBackground)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.horizontal)
        .accessibilityLabel("하드웨어 볼륨 버튼 사용")
    }
}

// MARK: - Media Button

struct MediaButton: View {
    let icon: String
    let size: CGFloat
    var isCompact: Bool = false
    var isPrimary: Bool = false
    var accessibilityLabel: String = ""
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: size, weight: .medium))
                .foregroundStyle(SnapColors.label)
                .frame(width: buttonSize, height: buttonSize)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .strokeBorder(SnapColors.separator, lineWidth: 1)
                )
                .scaleEffect(isPressed ? 0.9 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibleControl()
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
        if isCompact {
            return isPrimary ? 64 : 48
        }
        return isPrimary ? 80 : 56
    }

    private var backgroundColor: Color {
        isPrimary ? SnapColors.tertiarySystemBackground : SnapColors.secondarySystemBackground
    }
}

#Preview {
    MediaView(
        store: Store(initialState: MediaFeature.State()) {
            MediaFeature()
        }
    )
}
