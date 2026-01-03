import SwiftUI
import Shared

@main
struct MacReceiverApp: App {
    @StateObject private var serverManager = ServerManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(serverManager: serverManager)
        } label: {
            MenuBarLabel(serverManager: serverManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(serverManager: serverManager)
        }
    }
}

// MARK: - MenuBar Label

struct MenuBarLabel: View {
    @ObservedObject var serverManager: ServerManager

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: iconName)
                .symbolRenderingMode(.hierarchical)
        }
    }

    private var iconName: String {
        if serverManager.connectedDevice != nil {
            return "antenna.radiowaves.left.and.right"
        } else if serverManager.isRunning {
            return "antenna.radiowaves.left.and.right.slash"
        } else {
            return "xmark.circle"
        }
    }
}

// MARK: - MenuBar View

struct MenuBarView: View {
    @ObservedObject var serverManager: ServerManager
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Accessibility Warning
            if !accessibilityManager.isAccessibilityEnabled {
                accessibilityWarningSection
                    .padding()

                Divider()
            }

            // Status Section
            statusSection
                .padding()

            Divider()

            // Connection Section
            connectionSection
                .padding()

            Divider()

            // Actions
            actionsSection
        }
        .frame(width: 280)
        .onAppear {
            accessibilityManager.checkAccessibility()
        }
    }

    @ViewBuilder
    private var accessibilityWarningSection: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.orange)

            VStack(alignment: .leading, spacing: 2) {
                Text("접근성 권한 필요")
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text("입력 제어를 위해 권한이 필요합니다")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("허용") {
                accessibilityManager.requestAccessibility()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
        .padding(8)
        .background(Color.orange.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    @ViewBuilder
    private var statusSection: some View {
        HStack {
            Circle()
                .fill(statusColor)
                .frame(width: 10, height: 10)

            Text(statusText)
                .font(.headline)

            Spacer()

            Button(serverManager.isRunning ? "중지" : "시작") {
                serverManager.toggleServer()
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.small)
        }
    }

    private var statusColor: Color {
        if serverManager.connectedDevice != nil {
            return .green
        } else if serverManager.isRunning {
            return .orange
        } else {
            return .red
        }
    }

    private var statusText: String {
        if serverManager.connectedDevice != nil {
            return "연결됨"
        } else if serverManager.isRunning {
            return "대기 중"
        } else {
            return "중지됨"
        }
    }

    @ViewBuilder
    private var connectionSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let device = serverManager.connectedDevice {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundStyle(.blue)
                    Text(device)
                        .font(.subheadline)
                    Spacer()
                    Button {
                        serverManager.disconnectClient()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            } else {
                HStack {
                    Image(systemName: "iphone.slash")
                        .foregroundStyle(.secondary)
                    Text("연결된 디바이스 없음")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            if let error = serverManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Text("포트: \(NetworkConstants.tcpPort)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        VStack(spacing: 0) {
            Button {
                openSettings()
            } label: {
                HStack {
                    Image(systemName: "gear")
                    Text("설정...")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)

            Divider()

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                HStack {
                    Image(systemName: "power")
                    Text("종료")
                    Spacer()
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Settings View

struct SettingsView: View {
    @ObservedObject var serverManager: ServerManager

    var body: some View {
        TabView {
            GeneralSettingsView(serverManager: serverManager)
                .tabItem {
                    Label("일반", systemImage: "gear")
                }

            LogSettingsView(serverManager: serverManager)
                .tabItem {
                    Label("로그", systemImage: "doc.text")
                }
        }
        .frame(width: 450, height: 300)
    }
}

struct GeneralSettingsView: View {
    @ObservedObject var serverManager: ServerManager
    @ObservedObject private var accessibilityManager = AccessibilityManager.shared

    var body: some View {
        Form {
            Section {
                LabeledContent("서버 상태") {
                    Text(serverManager.isRunning ? "실행 중" : "중지됨")
                        .foregroundStyle(serverManager.isRunning ? .green : .red)
                }

                LabeledContent("TCP 포트") {
                    Text("\(NetworkConstants.tcpPort)")
                }

                LabeledContent("UDP 포트") {
                    Text("\(NetworkConstants.udpPort)")
                }
            }

            Section {
                LabeledContent("연결된 디바이스") {
                    Text(serverManager.connectedDevice ?? "없음")
                }
            }

            Section("권한") {
                HStack {
                    LabeledContent("접근성 권한") {
                        HStack(spacing: 8) {
                            Image(systemName: accessibilityManager.isAccessibilityEnabled
                                  ? "checkmark.circle.fill"
                                  : "exclamationmark.triangle.fill")
                                .foregroundStyle(accessibilityManager.isAccessibilityEnabled ? .green : .orange)

                            Text(accessibilityManager.isAccessibilityEnabled ? "허용됨" : "필요함")
                                .foregroundStyle(accessibilityManager.isAccessibilityEnabled ? .green : .orange)
                        }
                    }

                    if !accessibilityManager.isAccessibilityEnabled {
                        Button("설정 열기") {
                            accessibilityManager.openSystemPreferences()
                        }
                        .buttonStyle(.borderedProminent)
                        .controlSize(.small)
                    }
                }
            }
        }
        .formStyle(.grouped)
        .padding()
        .onAppear {
            accessibilityManager.checkAccessibility()
        }
    }
}

struct LogSettingsView: View {
    @ObservedObject var serverManager: ServerManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("활동 로그")
                    .font(.headline)
                Spacer()
                Button("지우기") {
                    serverManager.receivedPackets.removeAll()
                }
            }

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(serverManager.receivedPackets, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .background(Color(.textBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
        .padding()
    }
}

// MARK: - Server Manager

@MainActor
final class ServerManager: ObservableObject {
    @Published var isRunning: Bool = false
    @Published var connectedDevice: String?
    @Published var lastError: String?
    @Published var receivedPackets: [String] = []

    private var server: SnapServer?

    init() {
        startServer()
    }

    func startServer() {
        guard server == nil else { return }

        server = SnapServer()
        server?.delegate = self

        do {
            try server?.start()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stopServer() {
        server?.stop()
        server = nil
    }

    func toggleServer() {
        if isRunning {
            stopServer()
        } else {
            startServer()
        }
    }

    func disconnectClient() {
        server?.disconnectClient()
    }

    private func handlePacket(_ packet: DecodedPacket) {
        switch packet {
        case .mouseMove(let move, _):
            InputSimulator.shared.moveMouse(
                deltaX: CGFloat(move.deltaX),
                deltaY: CGFloat(move.deltaY)
            )
            logPacket("MouseMove: dx=\(move.deltaX), dy=\(move.deltaY)")

        case .mouseClick(let click, _):
            InputSimulator.shared.mouseClick(button: click.button, action: click.action)
            logPacket("MouseClick: \(click.button) \(click.action)")

        case .scroll(let scroll, _):
            InputSimulator.shared.scroll(
                deltaX: CGFloat(scroll.deltaX),
                deltaY: CGFloat(scroll.deltaY)
            )
            logPacket("Scroll: dx=\(scroll.deltaX), dy=\(scroll.deltaY)")

        case .keyEvent(let keyEvent, _):
            InputSimulator.shared.keyEvent(
                keyCode: keyEvent.keyCode,
                action: keyEvent.action,
                modifiers: keyEvent.modifiers
            )
            logPacket("KeyEvent: code=\(keyEvent.keyCode), action=\(keyEvent.action)")

        case .keyCombo(let combo, _):
            InputSimulator.shared.executeKeyCombo(
                keyCodes: combo.keyCodes,
                modifiers: combo.modifiers
            )
            logPacket("KeyCombo: \(combo.keyCodes)")

        case .mediaControl(let media, _):
            MediaController.shared.execute(command: media.command, volume: media.volume)
            logPacket("MediaControl: \(media.command)")

        case .windowSnap(let snap, _):
            WindowController.shared.snap(to: snap.position)
            logPacket("WindowSnap: \(snap.position)")

        case .appListRequest:
            let apps = AppController.shared.getRunningApps()
            let response = AppListResponse(apps: apps)
            server?.sendAppListResponse(response)
            logPacket("AppListRequest: sent \(apps.count) apps")

        case .appFocus(let focus, _):
            let success = AppController.shared.focusApp(bundleID: focus.bundleID, pid: focus.pid)
            logPacket("AppFocus: \(focus.bundleID) - \(success ? "success" : "failed")")

        case .presentation(let pres, _):
            // TODO: Presentation control
            logPacket("Presentation: \(pres.command)")

        case .voiceText(let voice, _):
            if voice.isFinal && !voice.text.isEmpty {
                InputSimulator.shared.typeText(voice.text)
            }
            logPacket("VoiceText: \(voice.text) (final: \(voice.isFinal))")

        case .siriCommand(let command, _):
            SiriController.shared.execute(command: command)
            logPacket("SiriCommand: \(command.action)")

        default:
            break
        }
    }

    private func logPacket(_ message: String) {
        let timestamp = DateFormatter.localizedString(
            from: Date(),
            dateStyle: .none,
            timeStyle: .medium
        )
        let logMessage = "[\(timestamp)] \(message)"

        receivedPackets.insert(logMessage, at: 0)

        // 로그 제한
        if receivedPackets.count > 100 {
            receivedPackets.removeLast()
        }
    }
}

// MARK: - SnapServerDelegate

extension ServerManager: SnapServerDelegate {
    nonisolated func serverDidStart(_ server: SnapServer) {
        Task { @MainActor in
            self.isRunning = true
            self.lastError = nil
        }
    }

    nonisolated func serverDidStop(_ server: SnapServer) {
        Task { @MainActor in
            self.isRunning = false
            self.connectedDevice = nil
        }
    }

    nonisolated func server(_ server: SnapServer, didAcceptConnection deviceName: String) {
        Task { @MainActor in
            self.connectedDevice = deviceName
            self.logPacket("Connected: \(deviceName)")
        }
    }

    nonisolated func server(_ server: SnapServer, didDisconnectFrom deviceName: String) {
        Task { @MainActor in
            self.connectedDevice = nil
            self.logPacket("Disconnected: \(deviceName)")
        }
    }

    nonisolated func server(_ server: SnapServer, didReceivePacket packet: DecodedPacket) {
        Task { @MainActor in
            self.handlePacket(packet)
        }
    }

    nonisolated func server(_ server: SnapServer, didFailWithError error: Error) {
        Task { @MainActor in
            self.lastError = error.localizedDescription
            self.logPacket("Error: \(error.localizedDescription)")
        }
    }
}

// MARK: - Content View

struct ContentView: View {
    @ObservedObject var serverManager: ServerManager

    var body: some View {
        VStack(spacing: 20) {
            // Status Header
            statusHeader

            Divider()

            // Connection Info
            connectionInfo

            Divider()

            // Log View
            logView

            // Controls
            controls
        }
        .frame(width: 400, height: 400)
        .padding()
    }

    @ViewBuilder
    private var statusHeader: some View {
        HStack {
            Circle()
                .fill(serverManager.isRunning ? .green : .red)
                .frame(width: 12, height: 12)

            Text(serverManager.isRunning ? "Server Running" : "Server Stopped")
                .font(.headline)

            Spacer()

            Button(serverManager.isRunning ? "Stop" : "Start") {
                serverManager.toggleServer()
            }
        }
    }

    @ViewBuilder
    private var connectionInfo: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let device = serverManager.connectedDevice {
                HStack {
                    Image(systemName: "iphone")
                        .foregroundStyle(.blue)
                    Text("Connected: \(device)")
                        .font(.subheadline)
                    Spacer()
                    Button("Disconnect") {
                        serverManager.disconnectClient()
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(.red)
                }
            } else {
                HStack {
                    Image(systemName: "wifi.slash")
                        .foregroundStyle(.secondary)
                    Text("Waiting for connection...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            }

            if let error = serverManager.lastError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
            }
        }
    }

    @ViewBuilder
    private var logView: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Activity Log")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    ForEach(serverManager.receivedPackets, id: \.self) { log in
                        Text(log)
                            .font(.system(.caption, design: .monospaced))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxHeight: 200)
            .background(Color(.textBackgroundColor).opacity(0.5))
            .clipShape(RoundedRectangle(cornerRadius: 6))
        }
    }

    @ViewBuilder
    private var controls: some View {
        HStack {
            Button("Clear Log") {
                serverManager.receivedPackets.removeAll()
            }
            .buttonStyle(.borderless)

            Spacer()

            Text("Port: \(NetworkConstants.tcpPort)")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

#Preview {
    ContentView(serverManager: ServerManager())
}
