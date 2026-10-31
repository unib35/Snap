import CoreImage
import SwiftUI
import Shared
import ServiceManagement

@main
struct MacReceiverApp: App {
    @StateObject private var serverManager = ServerManager()

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(serverManager: serverManager)
                .tint(SnapPalette.defaultAccent)
        } label: {
            MenuBarLabel(serverManager: serverManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView(serverManager: serverManager)
                .tint(SnapPalette.defaultAccent)
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
                .foregroundStyle(SnapPalette.warning)

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
        .background(SnapPalette.warning.opacity(0.1))
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
            return SnapPalette.statusConnected
        } else if serverManager.isRunning {
            return SnapPalette.statusDiscovering
        } else {
            return SnapPalette.statusDisconnected
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
                        .foregroundStyle(SnapPalette.accent)
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
                    .foregroundStyle(SnapPalette.destructive)
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
                .tint(SnapPalette.defaultAccent)
                .tabItem {
                    Label("일반", systemImage: "gear")
                }

            LogSettingsView(serverManager: serverManager)
                .tint(SnapPalette.defaultAccent)
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
    @State private var launchAtLogin = SMAppService.mainApp.status == .enabled

    var body: some View {
        Form {
            Section("시작") {
                Toggle("로그인 시 자동 시작", isOn: $launchAtLogin)
                    .onChange(of: launchAtLogin) { _, newValue in
                        setLaunchAtLogin(newValue)
                    }
            }

            Section {
                LabeledContent("서버 상태") {
                    Text(serverManager.isRunning ? "실행 중" : "중지됨")
                        .foregroundStyle(serverManager.isRunning ? SnapPalette.statusDiscovering : SnapPalette.statusDisconnected)
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
                                .foregroundStyle(accessibilityManager.isAccessibilityEnabled ? SnapPalette.success : SnapPalette.warning)

                            Text(accessibilityManager.isAccessibilityEnabled ? "허용됨" : "필요함")
                                .foregroundStyle(accessibilityManager.isAccessibilityEnabled ? SnapPalette.success : SnapPalette.warning)
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
            launchAtLogin = SMAppService.mainApp.status == .enabled
        }
    }

    private func setLaunchAtLogin(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // 실패 시 상태 롤백
            launchAtLogin = SMAppService.mainApp.status == .enabled
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

    // Pairing
    @Published var isPairingInProgress: Bool = false
    @Published var pairingDeviceName: String = ""
    @Published var pairingPinCode: String = ""
    @Published private(set) var trustedDevices: [TrustedDevice] = TrustedDevicesManager.shared.trustedDevices

    private var server: SnapServer?
    private var pairingWindow: NSWindow?
    private var nowPlayingTimer: Timer?
    private var lastNowPlayingInfo: NowPlayingInfo?
    private var lastVolumeState: VolumeState?

    init() {
        startServer()
    }

    func startServer() {
        guard !isRunning else { return }
        if server == nil {
            server = SnapServer()
            server?.delegate = self
        }

        do {
            try server?.start()
        } catch {
            lastError = error.localizedDescription
        }
    }

    func stopServer() {
        InputSimulator.shared.releaseAllInputs()
        stopNowPlayingUpdates()
        server?.stop()
        server = nil
        isRunning = false
        connectedDevice = nil
        clearPairingPresentation()
    }

    private func clearPairingPresentation() {
        isPairingInProgress = false
        pairingPinCode = ""
        pairingWindow?.close()
        pairingWindow = nil
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

    func cancelPairing() {
        server?.cancelPairing()
    }

    // MARK: - Trusted Devices

    /// 신뢰한 iPhone 하나를 지웁니다. 다음 연결 때 QR 페어링을 다시 해야 합니다.
    func forgetTrustedDevice(deviceID: String) {
        do {
            if let server {
                try server.revokeTrustedDevice(deviceID: deviceID)
            } else {
                TrustedDevicesManager.shared.removeTrustedDevice(deviceID: deviceID)
                try KeychainPairingCredentialStore.shared.remove(for: "server:" + deviceID)
            }
        } catch {
            lastError = error.localizedDescription
        }
        refreshTrustedDevices()
    }

    /// 신뢰한 iPhone을 모두 지웁니다.
    func forgetAllTrustedDevices() {
        for device in trustedDevices {
            forgetTrustedDevice(deviceID: device.deviceID)
        }
    }

    func refreshTrustedDevices() {
        trustedDevices = TrustedDevicesManager.shared.trustedDevices
    }

    private func showPairingWindow() {
        pairingWindow?.close()
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 400, height: 460),
            styleMask: [.titled],
            backing: .buffered,
            defer: false
        )
        window.title = "Snap 기기 페어링"
        window.isReleasedWhenClosed = false
        window.contentViewController = NSHostingController(rootView: PairingView(serverManager: self))
        window.center()
        window.makeKeyAndOrderFront(nil)
        NSApplication.shared.activate(ignoringOtherApps: true)
        pairingWindow = window
    }

    // MARK: - Now Playing

    private func startNowPlayingUpdates() {
        stopNowPlayingUpdates()

        // 즉시 한 번 전송
        sendNowPlayingInfoIfChanged()
        sendVolumeStateIfChanged()

        // 2초마다 업데이트 전송
        nowPlayingTimer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.sendNowPlayingInfoIfChanged()
                self?.sendVolumeStateIfChanged()
            }
        }
    }

    private func stopNowPlayingUpdates() {
        nowPlayingTimer?.invalidate()
        nowPlayingTimer = nil
        lastNowPlayingInfo = nil
        lastVolumeState = nil
    }

    private func sendNowPlayingInfoIfChanged() {
        let currentInfo = MediaController.shared.getNowPlayingInfo()

        // 정보가 변경되었을 때만 전송
        if currentInfo != lastNowPlayingInfo {
            lastNowPlayingInfo = currentInfo
            server?.sendNowPlayingInfo(currentInfo)
            logPacket("NowPlaying: \(currentInfo.isEmpty ? "No media" : "\(currentInfo.title) - \(currentInfo.artist)")")
        }
    }

    private func sendVolumeStateIfChanged() {
        guard let currentState = MediaController.shared.currentVolumeState(),
              currentState != lastVolumeState else { return }
        lastVolumeState = currentState
        server?.sendVolumeState(currentState)
        logPacket("Volume: \(Int(currentState.volume * 100))%\(currentState.isMuted ? " (muted)" : "")")
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

        case .pinch(let pinch, _):
            InputSimulator.shared.pinchZoom(scale: CGFloat(pinch.scale), phase: pinch.phase)
            logPacket("Pinch: scale=\(pinch.scale), phase=\(pinch.phase)")

        case .gyroData(let gyro, _):
            // attitude.y (roll) → 수평 이동 (X)
            // attitude.x (pitch) → 수직 이동 (Y)
            let deltaX = CGFloat(gyro.attitude.y * gyro.sensitivity)
            let deltaY = CGFloat(gyro.attitude.x * gyro.sensitivity)
            InputSimulator.shared.moveMouse(deltaX: deltaX, deltaY: deltaY)

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
            if [.volumeUp, .volumeDown, .mute].contains(media.command) {
                // 볼륨 키는 Mac이 정한 단계만큼 바뀌므로 실제 값을 바로 알려준다.
                Task { @MainActor [weak self] in
                    try? await Task.sleep(for: .milliseconds(200))
                    self?.sendVolumeStateIfChanged()
                }
            }

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
            let executed = PresentationController.shared.execute(command: pres.command)
            logPacket("Presentation: \(pres.command)\(executed ? "" : " - unsupported app")")

        case .voiceText(let voice, _):
            if voice.isFinal && !voice.text.isEmpty {
                InputSimulator.shared.typeText(voice.text)
            }
            logPacket("VoiceText: \(voice.text) (final: \(voice.isFinal))")

        case .siriCommand(let command, _):
            SiriController.shared.execute(command: command)
            logPacket("SiriCommand: \(command.action)")

        case .openURL(let openURL, _):
            if let url = URL(string: openURL.url) {
                NSWorkspace.shared.open(url)
                logPacket("OpenURL: \(openURL.url)")
            } else {
                logPacket("OpenURL: Invalid URL - \(openURL.url)")
            }

        case .systemCommand(let command, _):
            SystemController.shared.execute(command: command.command)
            logPacket("SystemCommand: \(command.command)")

        case .shortsCommand(let command, _):
            ShortsController.shared.execute(command: command)
            logPacket("ShortsCommand: \(command.platform) - \(command.action)")

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
        DispatchQueue.main.async {
            guard self.server === server else { return }
            self.isRunning = true
            self.lastError = nil
        }
    }

    nonisolated func serverDidStop(_ server: SnapServer) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            self.isRunning = false
            self.connectedDevice = nil
            InputSimulator.shared.releaseAllInputs()
            self.stopNowPlayingUpdates()
            self.clearPairingPresentation()
        }
    }

    nonisolated func server(_ server: SnapServer, didAcceptConnection deviceName: String) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            self.connectedDevice = deviceName
            self.logPacket("Connected: \(deviceName)")
            self.startNowPlayingUpdates()
        }
    }

    nonisolated func server(_ server: SnapServer, didDisconnectFrom deviceName: String) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            InputSimulator.shared.releaseAllInputs()
            self.connectedDevice = nil
            self.logPacket("Disconnected: \(deviceName)")
            self.stopNowPlayingUpdates()
        }
    }

    nonisolated func server(_ server: SnapServer, didReceivePacket packet: DecodedPacket) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            guard self.isRunning, self.connectedDevice != nil else { return }
            self.handlePacket(packet)
        }
    }

    nonisolated func server(_ server: SnapServer, didFailWithError error: Error) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            self.lastError = error.localizedDescription
            self.logPacket("Error: \(error.localizedDescription)")
        }
    }

    nonisolated func server(_ server: SnapServer, showPairingCode code: String, forDevice deviceName: String) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            self.isPairingInProgress = true
            self.pairingDeviceName = deviceName
            self.pairingPinCode = code
            self.showPairingWindow()
            self.logPacket("Pairing requested: \(deviceName)")
        }
    }

    nonisolated func server(_ server: SnapServer, didCompletePairing success: Bool, deviceName: String) {
        DispatchQueue.main.async {
            guard self.server === server else { return }
            self.clearPairingPresentation()
            self.refreshTrustedDevices()
            if success {
                self.logPacket("Pairing successful: \(deviceName)")
            } else {
                self.logPacket("Pairing failed: \(deviceName)")
            }
        }
    }
}


private struct PairingView: View {
    @ObservedObject var serverManager: ServerManager

    private var qrImage: NSImage? {
        guard let data = serverManager.pairingPinCode.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else { return nil }
        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("M", forKey: "inputCorrectionLevel")
        guard let output = filter.outputImage?.transformed(by: CGAffineTransform(scaleX: 8, y: 8)),
              let image = CIContext().createCGImage(output, from: output.extent) else { return nil }
        return NSImage(cgImage: image, size: NSSize(width: 260, height: 260))
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(serverManager.pairingDeviceName).font(.headline)
            Text("iPhone의 Snap으로 이 코드를 스캔하세요")
                .multilineTextAlignment(.center)
            if let image = qrImage {
                Image(nsImage: image)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 240, height: 240)
                    .padding(12)
                    .background(SnapPalette.qrBackground)
                    .accessibilityLabel("Snap 보안 페어링 QR 코드. 코드 복사 버튼으로도 연결할 수 있습니다.")
            }
            Text("코드는 60초 동안 이 연결에서만 사용할 수 있습니다.")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button("코드 복사") {
                    NSPasteboard.general.clearContents()
                    NSPasteboard.general.setString(serverManager.pairingPinCode, forType: .string)
                }
                Button("연결 거부", role: .cancel) { serverManager.cancelPairing() }
                    .keyboardShortcut(.cancelAction)
            }
        }
        .padding(24)
        .frame(minWidth: 350)
    }
}
