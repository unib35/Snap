import ActivityKit
import ComposableArchitecture
import Foundation
import os.log
import Shared
import WidgetKit

private extension Logger {
    static let widget = Logger(subsystem: "com.snap.app", category: "Widget")
}

// MARK: - Widget Connection State

/// 위젯과 Live Activity에 전달하는 연결 상태
public enum WidgetConnectionState: Equatable, Sendable {
    case disconnected
    case reconnecting(deviceName: String)
    case connected(deviceName: String)

    public init(status: ConnectionStatus) {
        switch status {
        case .connected(let device):
            self = .connected(deviceName: device.name)
        case .reconnecting(let device, _):
            self = .reconnecting(deviceName: device.name)
        case .disconnected, .discovering, .connecting:
            self = .disconnected
        }
    }

    var isConnected: Bool {
        if case .connected = self { return true }
        return false
    }

    var deviceName: String? {
        switch self {
        case .connected(let name), .reconnecting(let name):
            return name
        case .disconnected:
            return nil
        }
    }
}

// MARK: - Widget Client

/// 위젯·제어 센터·Live Activity에 앱 상태를 전달하는 클라이언트
public struct WidgetClient: Sendable {
    public var updateConnection: @Sendable (WidgetConnectionState) async -> Void
    public var updateMacros: @Sendable ([WidgetMacroItem]) async -> Void
    public var updateNowPlaying: @Sendable (WidgetNowPlaying?) async -> Void
}

extension WidgetClient: DependencyKey {
    public static var liveValue: WidgetClient {
        let store = WidgetDataStore.shared

        return WidgetClient(
            updateConnection: { state in
                store.updateConnectionStatus(isConnected: state.isConnected, deviceName: state.deviceName)
                WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.quickConnect)
                WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.mediaControl)
                if #available(iOS 18.0, *) {
                    ControlCenter.shared.reloadControls(ofKind: WidgetKind.connectionControl)
                }
                await LiveActivityManager.apply(state)
            },
            updateMacros: { macros in
                store.saveMacros(macros)
                WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.macro)
            },
            updateNowPlaying: { nowPlaying in
                store.saveNowPlaying(nowPlaying)
                WidgetCenter.shared.reloadTimelines(ofKind: WidgetKind.mediaControl)
            }
        )
    }

    public static var testValue: WidgetClient {
        WidgetClient(
            updateConnection: { _ in },
            updateMacros: { _ in },
            updateNowPlaying: { _ in }
        )
    }
}

public extension DependencyValues {
    var widgetClient: WidgetClient {
        get { self[WidgetClient.self] }
        set { self[WidgetClient.self] = newValue }
    }
}

// MARK: - Live Activity Manager

/// 연결 상태에 맞춰 Live Activity를 시작·갱신·종료
enum LiveActivityManager {
    static func apply(_ state: WidgetConnectionState) async {
        let activities = Activity<SnapConnectionAttributes>.activities
        let content = ActivityContent(
            state: SnapConnectionAttributes.ContentState(
                isConnected: state.isConnected,
                deviceName: state.deviceName
            ),
            staleDate: nil
        )

        switch state {
        case .connected:
            if activities.isEmpty {
                start(content)
            } else {
                for activity in activities {
                    await activity.update(content)
                }
            }

        case .reconnecting:
            for activity in activities {
                await activity.update(content)
            }

        case .disconnected:
            for activity in activities {
                await activity.end(content, dismissalPolicy: .after(.now + 30))
            }
        }
    }

    private static func start(_ content: ActivityContent<SnapConnectionAttributes.ContentState>) {
        guard ActivityAuthorizationInfo().areActivitiesEnabled else { return }

        do {
            _ = try Activity.request(
                attributes: SnapConnectionAttributes(),
                content: content,
                pushType: nil
            )
        } catch {
            Logger.widget.error("Failed to start Live Activity: \(error.localizedDescription)")
        }
    }
}
