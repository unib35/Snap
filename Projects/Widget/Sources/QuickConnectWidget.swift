import SwiftUI
import WidgetKit

// MARK: - Quick Connect Widget

struct QuickConnectWidget: Widget {
    let kind: String = "QuickConnectWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuickConnectProvider()) { entry in
            QuickConnectWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("빠른 연결")
        .description("Mac과 빠르게 연결합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Entry

struct QuickConnectEntry: TimelineEntry {
    let date: Date
    let isConnected: Bool
    let deviceName: String?
}

// MARK: - Provider

struct QuickConnectProvider: TimelineProvider {
    func placeholder(in context: Context) -> QuickConnectEntry {
        QuickConnectEntry(date: Date(), isConnected: false, deviceName: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (QuickConnectEntry) -> Void) {
        let entry = QuickConnectEntry(
            date: Date(),
            isConnected: WidgetDataManager.isConnected,
            deviceName: WidgetDataManager.connectedDeviceName
        )
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<QuickConnectEntry>) -> Void) {
        let entry = QuickConnectEntry(
            date: Date(),
            isConnected: WidgetDataManager.isConnected,
            deviceName: WidgetDataManager.connectedDeviceName
        )

        // Update every 5 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// MARK: - Widget View

struct QuickConnectWidgetView: View {
    var entry: QuickConnectEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(entry.isConnected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 60, height: 60)

                Image(systemName: entry.isConnected ? "wifi" : "wifi.slash")
                    .font(.system(size: 28))
                    .foregroundStyle(entry.isConnected ? .green : .secondary)
            }

            VStack(spacing: 4) {
                Text(entry.isConnected ? "연결됨" : "연결 안됨")
                    .font(.headline)
                    .foregroundStyle(entry.isConnected ? .primary : .secondary)

                if let deviceName = entry.deviceName, entry.isConnected {
                    Text(deviceName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "snap://connect"))
    }

    private var mediumView: some View {
        HStack(spacing: 16) {
            // Connection Status
            ZStack {
                Circle()
                    .fill(entry.isConnected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 70, height: 70)

                Image(systemName: entry.isConnected ? "wifi" : "wifi.slash")
                    .font(.system(size: 32))
                    .foregroundStyle(entry.isConnected ? .green : .secondary)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Snap")
                    .font(.title2.weight(.bold))

                if entry.isConnected {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.green)
                        Text(entry.deviceName ?? "Mac")
                            .foregroundStyle(.secondary)
                    }
                    .font(.subheadline)
                } else {
                    Text("탭하여 연결")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            // Quick Actions
            if entry.isConnected {
                VStack(spacing: 8) {
                    if let trackpadURL = URL(string: "snap://trackpad") {
                        Link(destination: trackpadURL) {
                            QuickActionButton(icon: "hand.draw", label: "트랙패드")
                        }
                    }
                    if let keyboardURL = URL(string: "snap://keyboard") {
                        Link(destination: keyboardURL) {
                            QuickActionButton(icon: "keyboard", label: "키보드")
                        }
                    }
                }
            }
        }
        .padding(.horizontal, 4)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .widgetURL(URL(string: "snap://connect"))
    }
}

// MARK: - Quick Action Button

struct QuickActionButton: View {
    let icon: String
    let label: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.accentColor.opacity(0.15))
        .clipShape(Capsule())
        .foregroundStyle(Color.accentColor)
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    QuickConnectWidget()
} timeline: {
    QuickConnectEntry(date: .now, isConnected: false, deviceName: nil)
    QuickConnectEntry(date: .now, isConnected: true, deviceName: "MacBook Pro")
}

#Preview(as: .systemMedium) {
    QuickConnectWidget()
} timeline: {
    QuickConnectEntry(date: .now, isConnected: false, deviceName: nil)
    QuickConnectEntry(date: .now, isConnected: true, deviceName: "MacBook Pro")
}
