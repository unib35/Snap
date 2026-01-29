import SwiftUI
import WidgetKit

// MARK: - Media Control Widget

/// Large 사이즈 위젯으로 미디어 컨트롤 기능 제공
struct MediaControlWidget: Widget {
    let kind: String = "MediaControlWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MediaControlProvider()) { entry in
            MediaControlWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("미디어 컨트롤")
        .description("Mac의 미디어 재생을 제어합니다.")
        .supportedFamilies([.systemLarge])
    }
}

// MARK: - Entry

struct MediaControlEntry: TimelineEntry {
    let date: Date
    let isConnected: Bool
    let deviceName: String?
    let nowPlaying: WidgetNowPlaying?
}

struct WidgetNowPlaying: Codable {
    let title: String
    let artist: String
    let album: String
    let isPlaying: Bool
    let appName: String
}

// MARK: - Provider

struct MediaControlProvider: TimelineProvider {
    func placeholder(in context: Context) -> MediaControlEntry {
        MediaControlEntry(
            date: Date(),
            isConnected: true,
            deviceName: "MacBook Pro",
            nowPlaying: WidgetNowPlaying(
                title: "Song Title",
                artist: "Artist Name",
                album: "Album Name",
                isPlaying: true,
                appName: "Music"
            )
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (MediaControlEntry) -> Void) {
        let entry = MediaControlEntry(
            date: Date(),
            isConnected: WidgetDataManager.isConnected,
            deviceName: WidgetDataManager.connectedDeviceName,
            nowPlaying: WidgetDataManager.loadNowPlaying()
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MediaControlEntry>) -> Void) {
        let entry = MediaControlEntry(
            date: Date(),
            isConnected: WidgetDataManager.isConnected,
            deviceName: WidgetDataManager.connectedDeviceName,
            nowPlaying: WidgetDataManager.loadNowPlaying()
        )

        // Update every minute for now playing info
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 1, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct MediaControlWidgetView: View {
    var entry: MediaControlEntry

    var body: some View {
        VStack(spacing: 16) {
            // Header
            headerView

            if entry.isConnected {
                // Now Playing Info
                nowPlayingView

                Spacer()

                // Playback Controls
                playbackControls

                // Volume Controls
                volumeControls
            } else {
                // Disconnected State
                disconnectedView
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Header

    private var headerView: some View {
        HStack {
            Image(systemName: "music.note")
                .foregroundStyle(.secondary)
            Text("미디어 컨트롤")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Spacer()

            // Connection Status
            HStack(spacing: 4) {
                Circle()
                    .fill(entry.isConnected ? Color.green : Color.red)
                    .frame(width: 6, height: 6)
                Text(entry.deviceName ?? (entry.isConnected ? "연결됨" : "연결 안됨"))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Now Playing

    private var nowPlayingView: some View {
        HStack(spacing: 16) {
            // Album Art Placeholder
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: appIcon)
                    .font(.system(size: 32))
                    .foregroundStyle(appIconColor)
            }

            // Track Info
            VStack(alignment: .leading, spacing: 4) {
                if let nowPlaying = entry.nowPlaying {
                    // App Badge
                    HStack(spacing: 4) {
                        Circle()
                            .fill(nowPlaying.isPlaying ? Color.green : Color.orange)
                            .frame(width: 6, height: 6)
                        Text(nowPlaying.appName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Text(nowPlaying.title)
                        .font(.headline)
                        .lineLimit(1)

                    Text(nowPlaying.artist)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)

                    if !nowPlaying.album.isEmpty {
                        Text(nowPlaying.album)
                            .font(.caption)
                            .foregroundStyle(.tertiary)
                            .lineLimit(1)
                    }
                } else {
                    Text("재생 중인 항목 없음")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Text("Mac에서 음악을 재생하세요")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }

            Spacer()
        }
    }

    private var appIcon: String {
        guard let nowPlaying = entry.nowPlaying else { return "music.note" }
        switch nowPlaying.appName.lowercased() {
        case "music": return "music.note"
        case "spotify": return "waveform"
        default: return nowPlaying.isPlaying ? "play.circle" : "pause.circle"
        }
    }

    private var appIconColor: Color {
        guard let nowPlaying = entry.nowPlaying else { return .secondary }
        switch nowPlaying.appName.lowercased() {
        case "music": return .pink
        case "spotify": return .green
        default: return .secondary
        }
    }

    // MARK: - Playback Controls

    private var playbackControls: some View {
        HStack(spacing: 24) {
            // Previous
            if let url = URL(string: "snap://media/previous") {
                Link(destination: url) {
                    MediaControlButton(icon: "backward.fill", size: .regular)
                }
            }

            // Play/Pause
            if let url = URL(string: "snap://media/playpause") {
                Link(destination: url) {
                    MediaControlButton(
                        icon: entry.nowPlaying?.isPlaying == true ? "pause.fill" : "play.fill",
                        size: .large
                    )
                }
            }

            // Next
            if let url = URL(string: "snap://media/next") {
                Link(destination: url) {
                    MediaControlButton(icon: "forward.fill", size: .regular)
                }
            }
        }
    }

    // MARK: - Volume Controls

    private var volumeControls: some View {
        HStack(spacing: 16) {
            // Volume Down
            if let url = URL(string: "snap://media/volumedown") {
                Link(destination: url) {
                    Image(systemName: "speaker.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            // Volume Bar (visual indicator)
            RoundedRectangle(cornerRadius: 4)
                .fill(Color.gray.opacity(0.3))
                .frame(height: 8)
                .overlay(alignment: .leading) {
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.accentColor)
                            .frame(width: geo.size.width * 0.6) // Placeholder 60%
                    }
                }

            // Volume Up
            if let url = URL(string: "snap://media/volumeup") {
                Link(destination: url) {
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }

            // Mute
            if let url = URL(string: "snap://media/mute") {
                Link(destination: url) {
                    Image(systemName: "speaker.slash.fill")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .frame(width: 44, height: 44)
                        .background(Color.gray.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
    }

    // MARK: - Disconnected View

    private var disconnectedView: some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 80)

                Image(systemName: "wifi.slash")
                    .font(.system(size: 36))
                    .foregroundStyle(.secondary)
            }

            Text("Mac에 연결되지 않음")
                .font(.headline)
                .foregroundStyle(.secondary)

            Text("앱을 열어 연결하세요")
                .font(.caption)
                .foregroundStyle(.tertiary)

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "snap://connect"))
    }
}

// MARK: - Media Control Button

struct MediaControlButton: View {
    enum Size {
        case regular
        case large

        var iconSize: CGFloat {
            switch self {
            case .regular: return 20
            case .large: return 28
            }
        }

        var buttonSize: CGFloat {
            switch self {
            case .regular: return 50
            case .large: return 70
            }
        }
    }

    let icon: String
    let size: Size

    var body: some View {
        ZStack {
            Circle()
                .fill(size == .large ? Color.accentColor : Color.gray.opacity(0.2))
                .frame(width: size.buttonSize, height: size.buttonSize)

            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .medium))
                .foregroundStyle(size == .large ? .white : .primary)
        }
    }
}

// MARK: - Preview

#Preview(as: .systemLarge) {
    MediaControlWidget()
} timeline: {
    MediaControlEntry(
        date: .now,
        isConnected: false,
        deviceName: nil,
        nowPlaying: nil
    )
    MediaControlEntry(
        date: .now,
        isConnected: true,
        deviceName: "MacBook Pro",
        nowPlaying: WidgetNowPlaying(
            title: "Bohemian Rhapsody",
            artist: "Queen",
            album: "A Night at the Opera",
            isPlaying: true,
            appName: "Music"
        )
    )
}
