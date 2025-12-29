import SwiftUI
import Shared

@main
struct MacReceiverApp: App {
    @StateObject private var serverManager = ServerManager()

    var body: some Scene {
        WindowGroup {
            ContentView(serverManager: serverManager)
        }
        .windowResizability(.contentSize)
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
            // TODO: Implement media control
            logPacket("MediaControl: \(media.command)")

        case .windowSnap(let snap, _):
            // TODO: Implement window snap
            logPacket("WindowSnap: \(snap.position)")

        case .appListRequest:
            // TODO: Send app list response
            logPacket("AppListRequest")

        case .appFocus(let focus, _):
            // TODO: Focus app
            logPacket("AppFocus: \(focus.bundleID)")

        case .presentation(let pres, _):
            // TODO: Presentation control
            logPacket("Presentation: \(pres.command)")

        case .voiceText(let voice, _):
            // TODO: Type text
            logPacket("VoiceText: \(voice.text)")

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
