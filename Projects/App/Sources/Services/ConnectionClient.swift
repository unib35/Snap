import Foundation
import ComposableArchitecture
import Shared

/// TCA 의존성 클라이언트 - 연결 관리
public struct ConnectionClient: Sendable {
    // Discovery
    public var startDiscovery: @Sendable () async -> AsyncStream<DiscoveryEvent>
    public var stopDiscovery: @Sendable () async -> Void

    // Connection
    public var connect: @Sendable (String, UInt16) async throws -> AsyncStream<ConnectionEvent>
    public var disconnect: @Sendable () async -> Void

    // Send
    public var sendMouseMove: @Sendable (Float, Float) async -> Void
    public var sendMouseClick: @Sendable (MouseClick.Button, MouseClick.Action) async -> Void
    public var sendScroll: @Sendable (Float, Float, Bool) async -> Void
    public var sendGyroData: @Sendable (GyroData) async -> Void
    public var sendKeyEvent: @Sendable (UInt32, KeyEvent.Action, UInt32) async -> Void
    public var sendKeyCombo: @Sendable ([UInt32], UInt32) async -> Void
    public var sendMediaControl: @Sendable (MediaControl.Command, Float) async -> Void
    public var sendWindowSnap: @Sendable (WindowSnap.Position) async -> Void
    public var requestAppList: @Sendable () async -> Void
    public var sendAppFocus: @Sendable (String, UInt32) async -> Void
    public var sendSiriCommand: @Sendable (SiriCommand.Action, String) async -> Void
    public var sendVoiceText: @Sendable (String, Bool) async -> Void
}

// MARK: - Events

public enum DiscoveryEvent: Equatable, Sendable {
    case deviceFound(DiscoveredDevice)
    case deviceLost(String)
    case error(String)
}

public struct DiscoveredDevice: Equatable, Identifiable, Sendable {
    public let id: String
    public let name: String
    public let host: String
    public let port: UInt16

    public init(id: String, name: String, host: String, port: UInt16) {
        self.id = id
        self.name = name
        self.host = host
        self.port = port
    }
}

public enum ConnectionEvent: Equatable, Sendable {
    case connected(serverName: String)
    case disconnected(error: String?)
    case packet(PacketEvent)
    case error(String)
}

public enum PacketEvent: Equatable, Sendable {
    case appList([AppInfo])
    case error(String)
}

// MARK: - Dependency Key

extension ConnectionClient: DependencyKey {
    public static var liveValue: ConnectionClient {
        let actor = ConnectionActor()

        return ConnectionClient(
            startDiscovery: { await actor.startDiscovery() },
            stopDiscovery: { await actor.stopDiscovery() },
            connect: { host, port in try await actor.connect(host: host, port: port) },
            disconnect: { await actor.disconnect() },
            sendMouseMove: { dx, dy in await actor.sendMouseMove(deltaX: dx, deltaY: dy) },
            sendMouseClick: { button, action in await actor.sendMouseClick(button: button, action: action) },
            sendScroll: { dx, dy, inertia in await actor.sendScroll(deltaX: dx, deltaY: dy, isInertia: inertia) },
            sendGyroData: { gyroData in await actor.sendGyroData(gyroData) },
            sendKeyEvent: { code, action, mods in await actor.sendKeyEvent(keyCode: code, action: action, modifiers: mods) },
            sendKeyCombo: { codes, mods in await actor.sendKeyCombo(keyCodes: codes, modifiers: mods) },
            sendMediaControl: { cmd, vol in await actor.sendMediaControl(command: cmd, volume: vol) },
            sendWindowSnap: { pos in await actor.sendWindowSnap(position: pos) },
            requestAppList: { await actor.requestAppList() },
            sendAppFocus: { bundleID, pid in await actor.sendAppFocus(bundleID: bundleID, pid: pid) },
            sendSiriCommand: { action, text in await actor.sendSiriCommand(action: action, text: text) },
            sendVoiceText: { text, isFinal in await actor.sendVoiceText(text: text, isFinal: isFinal) }
        )
    }

    public static var testValue: ConnectionClient {
        ConnectionClient(
            startDiscovery: { .finished },
            stopDiscovery: {},
            connect: { _, _ in .finished },
            disconnect: {},
            sendMouseMove: { _, _ in },
            sendMouseClick: { _, _ in },
            sendScroll: { _, _, _ in },
            sendGyroData: { _ in },
            sendKeyEvent: { _, _, _ in },
            sendKeyCombo: { _, _ in },
            sendMediaControl: { _, _ in },
            sendWindowSnap: { _ in },
            requestAppList: {},
            sendAppFocus: { _, _ in },
            sendSiriCommand: { _, _ in },
            sendVoiceText: { _, _ in }
        )
    }
}

public extension DependencyValues {
    var connectionClient: ConnectionClient {
        get { self[ConnectionClient.self] }
        set { self[ConnectionClient.self] = newValue }
    }
}

// MARK: - Connection Actor

private actor ConnectionActor: SnapClientDelegate, BonjourBrowserDelegate {
    private var client: SnapClient?
    private var browser: BonjourBrowser?

    private var discoveryContinuation: AsyncStream<DiscoveryEvent>.Continuation?
    private var connectionContinuation: AsyncStream<ConnectionEvent>.Continuation?

    // MARK: - Discovery

    func startDiscovery() -> AsyncStream<DiscoveryEvent> {
        AsyncStream { continuation in
            self.discoveryContinuation = continuation

            self.browser = BonjourBrowser()
            self.browser?.delegate = self
            self.browser?.startSearching()

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.stopDiscovery()
                }
            }
        }
    }

    func stopDiscovery() {
        browser?.stopSearching()
        browser = nil
        discoveryContinuation?.finish()
        discoveryContinuation = nil
    }

    // MARK: - Connection

    func connect(host: String, port: UInt16) throws -> AsyncStream<ConnectionEvent> {
        AsyncStream { continuation in
            self.connectionContinuation = continuation

            self.client = SnapClient()
            self.client?.delegate = self
            self.client?.connect(to: host, port: port)

            continuation.onTermination = { [weak self] _ in
                Task { [weak self] in
                    await self?.disconnect()
                }
            }
        }
    }

    func disconnect() {
        client?.disconnect()
        client = nil
        connectionContinuation?.finish()
        connectionContinuation = nil
    }

    // MARK: - Send Methods

    func sendMouseMove(deltaX: Float, deltaY: Float) {
        client?.sendMouseMove(deltaX: deltaX, deltaY: deltaY)
    }

    func sendMouseClick(button: MouseClick.Button, action: MouseClick.Action) {
        client?.sendMouseClick(button: button, action: action)
    }

    func sendScroll(deltaX: Float, deltaY: Float, isInertia: Bool) {
        client?.sendScroll(deltaX: deltaX, deltaY: deltaY, isInertia: isInertia)
    }

    func sendGyroData(_ gyroData: GyroData) {
        client?.sendGyroData(gyroData)
    }

    func sendKeyEvent(keyCode: UInt32, action: KeyEvent.Action, modifiers: UInt32) {
        client?.sendKeyEvent(keyCode: keyCode, action: action, modifiers: modifiers)
    }

    func sendKeyCombo(keyCodes: [UInt32], modifiers: UInt32) {
        client?.sendKeyCombo(keyCodes: keyCodes, modifiers: modifiers)
    }

    func sendMediaControl(command: MediaControl.Command, volume: Float) {
        client?.sendMediaControl(command: command, volume: volume)
    }

    func sendWindowSnap(position: WindowSnap.Position) {
        client?.sendWindowSnap(position: position)
    }

    func requestAppList() {
        client?.requestAppList()
    }

    func sendAppFocus(bundleID: String, pid: UInt32) {
        client?.sendAppFocus(bundleID: bundleID, pid: pid)
    }

    func sendSiriCommand(action: SiriCommand.Action, text: String) {
        client?.sendSiriCommand(action: action, text: text)
    }

    func sendVoiceText(text: String, isFinal: Bool) {
        client?.sendVoiceText(text: text, isFinal: isFinal)
    }

    // MARK: - SnapClientDelegate

    nonisolated func clientDidConnect(_ client: SnapClient) {
        Task {
            await self.handleConnect(serverName: client.serverDeviceName ?? "Mac")
        }
    }

    private func handleConnect(serverName: String) {
        connectionContinuation?.yield(.connected(serverName: serverName))
    }

    nonisolated func clientDidDisconnect(_ client: SnapClient, error: Error?) {
        Task {
            await self.handleDisconnect(error: error)
        }
    }

    private func handleDisconnect(error: Error?) {
        connectionContinuation?.yield(.disconnected(error: error?.localizedDescription))
        connectionContinuation?.finish()
        connectionContinuation = nil
        self.client = nil
    }

    nonisolated func client(_ client: SnapClient, didReceive packet: DecodedPacket) {
        Task {
            await self.handlePacket(packet)
        }
    }

    private func handlePacket(_ packet: DecodedPacket) {
        switch packet {
        case .appListResponse(let response, _):
            connectionContinuation?.yield(.packet(.appList(response.apps)))
        case .error(let snapError, _):
            connectionContinuation?.yield(.packet(.error(snapError.message)))
        default:
            break
        }
    }

    nonisolated func client(_ client: SnapClient, didFailWithError error: Error) {
        Task {
            await self.handleError(error)
        }
    }

    private func handleError(_ error: Error) {
        connectionContinuation?.yield(.error(error.localizedDescription))
    }

    // MARK: - BonjourBrowserDelegate

    nonisolated func bonjourBrowser(_ browser: BonjourBrowser, didFind service: DiscoveredService) {
        Task {
            await self.handleServiceFound(service)
        }
    }

    private func handleServiceFound(_ service: DiscoveredService) {
        let deviceID = service.txtRecord["deviceID"] ?? service.name
        let device = DiscoveredDevice(
            id: deviceID,
            name: service.name,
            host: service.host,
            port: service.port
        )
        discoveryContinuation?.yield(.deviceFound(device))
    }

    nonisolated func bonjourBrowser(_ browser: BonjourBrowser, didRemove service: DiscoveredService) {
        Task {
            await self.handleServiceLost(service.name)
        }
    }

    private func handleServiceLost(_ serviceName: String) {
        discoveryContinuation?.yield(.deviceLost(serviceName))
    }

    nonisolated func bonjourBrowser(_ browser: BonjourBrowser, didFailWithError error: Error) {
        Task {
            await self.handleBrowseError(error)
        }
    }

    private func handleBrowseError(_ error: Error) {
        discoveryContinuation?.yield(.error(error.localizedDescription))
    }
}
