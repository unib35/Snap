import ActivityKit
import SwiftUI
import WidgetKit

// MARK: - Connection Live Activity

/// Snap 연결 상태를 Lock Screen과 Dynamic Island에 표시하는 Live Activity
struct SnapLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: SnapConnectionAttributes.self) { context in
            // Lock Screen / Banner UI
            LockScreenView(context: context)
        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded Regions
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 6) {
                        Image(systemName: context.state.isConnected ? "wifi" : "wifi.slash")
                            .foregroundStyle(context.state.isConnected ? .green : .secondary)
                        Text(context.state.deviceName ?? "Mac")
                            .font(.caption.weight(.medium))
                    }
                }

                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(context.state.isConnected ? Color.green : Color.red)
                            .frame(width: 8, height: 8)
                        Text(context.state.isConnected ? "연결됨" : "연결 끊김")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                DynamicIslandExpandedRegion(.center) {
                    Text("Snap")
                        .font(.headline.weight(.bold))
                }

                DynamicIslandExpandedRegion(.bottom) {
                    HStack(spacing: 16) {
                        // Trackpad Button
                        if let trackpadURL = URL(string: "snap://trackpad") {
                            Link(destination: trackpadURL) {
                                LiveActivityButton(icon: "hand.draw", label: "트랙패드")
                            }
                        }

                        // Keyboard Button
                        if let keyboardURL = URL(string: "snap://keyboard") {
                            Link(destination: keyboardURL) {
                                LiveActivityButton(icon: "keyboard", label: "키보드")
                            }
                        }

                        // Media Button
                        if let mediaURL = URL(string: "snap://media") {
                            Link(destination: mediaURL) {
                                LiveActivityButton(icon: "music.note", label: "미디어")
                            }
                        }
                    }
                    .padding(.top, 8)
                }
            } compactLeading: {
                Image(systemName: context.state.isConnected ? "wifi" : "wifi.slash")
                    .foregroundStyle(context.state.isConnected ? .green : .secondary)
            } compactTrailing: {
                Circle()
                    .fill(context.state.isConnected ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
            } minimal: {
                Image(systemName: context.state.isConnected ? "wifi" : "wifi.slash")
                    .foregroundStyle(context.state.isConnected ? .green : .secondary)
            }
        }
    }
}

// MARK: - Lock Screen View

private struct LockScreenView: View {
    let context: ActivityViewContext<SnapConnectionAttributes>

    var body: some View {
        HStack(spacing: 16) {
            // Connection Status Icon
            ZStack {
                Circle()
                    .fill(context.state.isConnected ? Color.green.opacity(0.2) : Color.gray.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: context.state.isConnected ? "wifi" : "wifi.slash")
                    .font(.system(size: 24))
                    .foregroundStyle(context.state.isConnected ? .green : .secondary)
            }

            // Status Info
            VStack(alignment: .leading, spacing: 4) {
                Text("Snap")
                    .font(.headline.weight(.bold))

                HStack(spacing: 4) {
                    Circle()
                        .fill(context.state.isConnected ? Color.green : Color.red)
                        .frame(width: 6, height: 6)

                    if context.state.isConnected {
                        Text(context.state.deviceName ?? "Mac에 연결됨")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    } else {
                        Text("연결 끊김")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Spacer()

            // Quick Actions
            if context.state.isConnected {
                HStack(spacing: 8) {
                    if let trackpadURL = URL(string: "snap://trackpad") {
                        Link(destination: trackpadURL) {
                            Image(systemName: "hand.draw")
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                    }

                    if let keyboardURL = URL(string: "snap://keyboard") {
                        Link(destination: keyboardURL) {
                            Image(systemName: "keyboard")
                                .font(.body)
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.accentColor)
                                .clipShape(Circle())
                        }
                    }
                }
            }
        }
        .padding()
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(Color.white)
    }
}

// MARK: - Live Activity Button

private struct LiveActivityButton: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)
                .frame(width: 40, height: 40)
                .background(Color.accentColor)
                .clipShape(Circle())

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#Preview("Lock Screen", as: .content, using: SnapConnectionAttributes()) {
    SnapLiveActivity()
} contentStates: {
    SnapConnectionAttributes.ContentState(isConnected: true, deviceName: "MacBook Pro")
    SnapConnectionAttributes.ContentState(isConnected: false, deviceName: nil)
}

#Preview("Dynamic Island Expanded", as: .dynamicIsland(.expanded), using: SnapConnectionAttributes()) {
    SnapLiveActivity()
} contentStates: {
    SnapConnectionAttributes.ContentState(isConnected: true, deviceName: "MacBook Pro")
}

#Preview("Dynamic Island Compact", as: .dynamicIsland(.compact), using: SnapConnectionAttributes()) {
    SnapLiveActivity()
} contentStates: {
    SnapConnectionAttributes.ContentState(isConnected: true, deviceName: "MacBook Pro")
}
