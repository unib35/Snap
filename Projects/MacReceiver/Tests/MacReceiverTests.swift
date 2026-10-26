import CoreGraphics
import Foundation
import Network
import Shared
import Testing
@testable import MacReceiver

@Suite("Receiver input regression")
@MainActor
struct InputSimulatorTests {
    @Test func preservesEmojiAndCombiningCharacters() throws {
        var events: [CGEvent] = []
        let input = InputSimulator(postEvent: { events.append($0) })
        let text = "😀👨‍👩‍👧‍👦e\u{301}한"
        input.typeText(text)
        let downs = events.filter { $0.type == .keyDown }
        let reconstructed = downs.map { event in
            var length = 0
            event.keyboardGetUnicodeString(maxStringLength: 0, actualStringLength: &length, unicodeString: nil)
            var units = [UniChar](repeating: 0, count: length)
            event.keyboardGetUnicodeString(maxStringLength: length, actualStringLength: &length, unicodeString: &units)
            return String(decoding: units, as: UTF16.self)
        }
        .joined()
        #expect(reconstructed == text)
        #expect(events.count == text.count * 2)
    }

    @Test func movesToDestinationAndTracksDragUntilRelease() throws {
        var events: [CGEvent] = []
        let input = InputSimulator(postEvent: { events.append($0) }, mouseLocation: { CGPoint(x: 100, y: 200) })
        input.mouseClick(button: .left, action: .down)
        input.moveMouse(deltaX: 12.5, deltaY: -3)
        let drag = try #require(events.last)
        #expect(drag.type == .leftMouseDragged)
        #expect(drag.location == CGPoint(x: 112.5, y: 197))
        input.keyEvent(keyCode: 56, action: .down, modifiers: 1)
        input.releaseAllInputs()
        #expect(events.contains { $0.type == .leftMouseUp })
        // Modifier keys use flagsChanged events rather than ordinary keyUp.
        #expect(events.last?.type == .flagsChanged)
        #expect(events.last?.flags.contains(.maskShift) == false)
        #expect(events.last?.getIntegerValueField(.keyboardEventKeycode) == 56)
        input.moveMouse(deltaX: 1, deltaY: 0)
        #expect(events.last?.type == .mouseMoved)
    }

    @Test func ignoresOutOfRangeNetworkInput() {
        var events: [CGEvent] = []
        let input = InputSimulator(postEvent: { events.append($0) })
        input.keyEvent(keyCode: .max, action: .press, modifiers: 0)
        input.executeKeyCombo(keyCodes: [.max], modifiers: 8)
        input.moveMouse(deltaX: .infinity, deltaY: 0)
        input.scroll(deltaX: .nan, deltaY: 0)
        #expect(events.isEmpty)
    }

    @Test func convertsWindowCoordinatesAcrossDisplays() {
        #expect(WindowController.accessibilityFrame(
            from: CGRect(x: 0, y: 600, width: 800, height: 400), primaryScreenHeight: 1080
        ) == CGRect(x: 0, y: 80, width: 800, height: 400))
        #expect(WindowController.accessibilityFrame(
            from: CGRect(x: -1920, y: -200, width: 1920, height: 1080), primaryScreenHeight: 1080
        ) == CGRect(x: -1920, y: 200, width: 1920, height: 1080))
    }
}

private final class ServerSpy: SnapServerDelegate {
    var packets = 0
    var pin: String?
    var connected = false
    func serverDidStart(_ server: SnapServer) {}
    func serverDidStop(_ server: SnapServer) {}
    func server(_ server: SnapServer, didAcceptConnection deviceName: String) { connected = true }
    func server(_ server: SnapServer, didDisconnectFrom deviceName: String) { connected = false }
    func server(_ server: SnapServer, didReceivePacket packet: DecodedPacket) { packets += 1 }
    func server(_ server: SnapServer, didFailWithError error: Error) {}
    func server(_ server: SnapServer, showPairingCode code: String, forDevice deviceName: String) { self.pin = code }
    func server(_ server: SnapServer, didCompletePairing success: Bool, deviceName: String) {}
}

@Suite("Receiver session boundary")
struct ServerSessionTests {
    @Test func retainsAcceptedConnectionsAndRejectsUnpairedCommands() throws {
        let server = SnapServer(deviceName: "Test", credentialStore: TestCredentials(), certificateData: { Data("test certificate".utf8) })
        let spy = ServerSpy()
        server.delegate = spy
        weak var reference: TCPConnection?
        do {
            let connection = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
            reference = connection
            server.acceptTransportConnection(connection)
        }
        let connection = try #require(reference)
        let packet = try PacketDecoder.decode(PacketEncoder.encode(KeyEvent(keyCode: 36)))
        server.tcpConnection(connection, didReceive: packet)
        server.udpSocket(UDPSocket(), didReceive: packet, from: .hostPort(host: "127.0.0.1", port: 1), sessionID: UUID())
        #expect(spy.packets == 0)
        server.stop()
    }

    @Test func acceptsCommandsOnlyAfterSuccessfulPairing() throws {
        let server = SnapServer(deviceName: "Test", credentialStore: TestCredentials(), certificateData: { Data("test certificate".utf8) })
        let spy = ServerSpy()
        server.delegate = spy
        let connection = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(connection)
        let id = UUID().uuidString
        defer { TrustedDevicesManager.shared.removeTrustedDevice(deviceID: id); server.stop() }
        let handshake = Handshake(deviceName: "Test phone", deviceID: id)
        server.tcpConnection(connection, didReceive: try PacketDecoder.decode(PacketEncoder.encode(handshake)))
        let code = try PairingDisplayCode.decode(#require(spy.pin))
        #expect(!spy.connected)
        let response = PairingResponse(pinCode: code.pin, deviceName: "Test phone", deviceID: id, nonce: code.challenge)
        server.tcpConnection(connection, didReceive: try PacketDecoder.decode(PacketEncoder.encode(response, type: .pairingResponse)))
        #expect(spy.connected)
        let packet = try PacketDecoder.decode(PacketEncoder.encode(KeyEvent(keyCode: 36)))
        server.tcpConnection(connection, didReceive: packet)
        #expect(spy.packets == 1)
        let stranger = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(stranger)
        server.tcpConnection(stranger, didReceive: packet)
        #expect(spy.packets == 1)
    }
}

private final class TestCredentials: PairingCredentialStore, @unchecked Sendable {
    private let lock = NSLock()
    private var values: [String: PairingCredential] = [:]
    func load(for account: String) throws -> PairingCredential? { lock.withLock { values[account] } }
    func save(_ credential: PairingCredential, for account: String) throws { lock.withLock { values[account] = credential } }
    func remove(for account: String) throws { _ = lock.withLock { values.removeValue(forKey: account) } }
}

extension ServerSessionTests {
    @Test func trustedIDNeedsSecretAndPlaintextIsRejected() throws {
        let store = TestCredentials()
        let token = DatagramSession.makeKey()
        let id = UUID().uuidString
        TrustedDevicesManager.shared.addTrustedDevice(deviceID: id, deviceName: "Known phone")
        defer { TrustedDevicesManager.shared.removeTrustedDevice(deviceID: id) }
        try store.save(PairingCredential(token: token), for: "server:" + id)
        let server = SnapServer(deviceName: "Test", credentialStore: store, certificateData: { Data("certificate".utf8) })
        defer { server.stop() }
        let spy = ServerSpy()
        server.delegate = spy
        let plaintext = TCPConnection(host: "127.0.0.1", port: 1)
        server.acceptTransportConnection(plaintext)
        plaintext.connect()
        #expect(plaintext.state == .disconnected)
        let spoof = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(spoof)
        let wrong = Handshake(deviceName: "Known phone", deviceID: id, authenticationToken: DatagramSession.makeKey())
        server.tcpConnection(spoof, didReceive: try PacketDecoder.decode(PacketEncoder.encode(wrong)))
        #expect(!spy.connected)
        #expect(spy.pin != nil)
        server.stop()
        spy.pin = nil
        let valid = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(valid)
        let handshake = Handshake(deviceName: "Known phone", deviceID: id, authenticationToken: token)
        server.tcpConnection(valid, didReceive: try PacketDecoder.decode(PacketEncoder.encode(handshake)))
        #expect(spy.connected)
        #expect(spy.pin == nil)
    }

    @Test func rejectsPairingCodeFromAnotherSession() throws {
        let server = SnapServer(deviceName: "Test", credentialStore: TestCredentials(), certificateData: { Data("certificate".utf8) })
        defer { server.stop() }
        let spy = ServerSpy()
        server.delegate = spy
        let connection = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(connection)
        let id = UUID().uuidString
        let handshake = Handshake(deviceName: "Phone", deviceID: id)
        server.tcpConnection(connection, didReceive: try PacketDecoder.decode(PacketEncoder.encode(handshake)))
        let code = try PairingDisplayCode.decode(#require(spy.pin))
        let response = PairingResponse(pinCode: code.pin, deviceName: "Phone", deviceID: id, nonce: DatagramSession.makeKey())
        server.tcpConnection(connection, didReceive: try PacketDecoder.decode(PacketEncoder.encode(response, type: .pairingResponse)))
        #expect(!spy.connected)
        #expect(!TrustedDevicesManager.shared.isTrusted(deviceID: id))
    }
}

extension ServerSessionTests {
    @Test func revokingTrustedDeviceDisconnectsAndRequiresPairingAgain() throws {
        let store = TestCredentials()
        let trusted = TrustedDevicesManager(persistence: MockPersistence())
        let token = DatagramSession.makeKey()
        let id = UUID().uuidString
        trusted.addTrustedDevice(deviceID: id, deviceName: "Known phone")
        trusted.addTrustedDevice(deviceID: "other", deviceName: "Other phone")
        try store.save(PairingCredential(token: token), for: "server:" + id)
        let server = SnapServer(
            deviceName: "Test",
            credentialStore: store,
            certificateData: { Data("certificate".utf8) },
            trustedDevicesManager: trusted
        )
        defer { server.stop() }
        let spy = ServerSpy()
        server.delegate = spy
        let handshake = Handshake(deviceName: "Known phone", deviceID: id, authenticationToken: token)

        let first = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(first)
        server.tcpConnection(first, didReceive: try PacketDecoder.decode(PacketEncoder.encode(handshake)))
        #expect(spy.connected)

        try server.revokeTrustedDevice(deviceID: id)
        #expect(!spy.connected)
        #expect(try store.load(for: "server:" + id) == nil)
        #expect(server.trustedDevices.map(\.deviceID) == ["other"])

        let second = TCPConnection(host: "127.0.0.1", port: 1, useTLS: true)
        server.acceptTransportConnection(second)
        server.tcpConnection(second, didReceive: try PacketDecoder.decode(PacketEncoder.encode(handshake)))
        #expect(!spy.connected)
        #expect(spy.pin != nil)
    }
}
