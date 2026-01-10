import Testing
@testable import Shared
import Foundation

// MARK: - PacketHeader Tests

@Suite("PacketHeader Tests")
struct PacketHeaderTests {
    @Test("Header serialization round-trip")
    func headerRoundTrip() throws {
        let header = PacketHeader(
            type: .mouseMove,
            payloadLength: 100,
            timestamp: 1_234_567_890
        )

        let data = header.toData()
        let parsed = PacketHeader(data: data)

        #expect(parsed != nil)
        #expect(parsed?.magic == NetworkConstants.packetMagic)
        #expect(parsed?.version == NetworkConstants.protocolVersion)
        #expect(parsed?.type == .mouseMove)
        #expect(parsed?.payloadLength == 100)
        #expect(parsed?.timestamp == 1_234_567_890)
    }

    @Test("Header size is correct")
    func headerSize() {
        let header = PacketHeader(type: .handshake, payloadLength: 0)
        let data = header.toData()

        #expect(data.count == NetworkConstants.packetHeaderSize)
    }

    @Test("Invalid magic number returns nil")
    func invalidMagic() {
        var data = Data(repeating: 0, count: NetworkConstants.packetHeaderSize)
        // Wrong magic number
        data[0] = 0x00
        data[1] = 0x00

        let header = PacketHeader(data: data)
        #expect(header == nil)
    }

    @Test("Unsupported version returns nil")
    func unsupportedVersion() {
        var data = PacketHeader(type: .handshake, payloadLength: 0).toData()
        // Wrong version
        data[2] = 0xFF

        let header = PacketHeader(data: data)
        #expect(header == nil)
    }

    @Test("Too short data returns nil")
    func tooShortData() {
        let data = Data(repeating: 0, count: 4)
        let header = PacketHeader(data: data)
        #expect(header == nil)
    }

    @Test("Header isValid property")
    func headerIsValid() {
        let header = PacketHeader(type: .mouseMove, payloadLength: 0)
        #expect(header.isValid == true)
    }
}

// MARK: - PacketEncoder Tests

@Suite("PacketEncoder Tests")
struct PacketEncoderTests {
    @Test("Encode MouseMove")
    func encodeMouseMove() throws {
        let message = MouseMove(deltaX: 10.5, deltaY: -5.25)
        let data = try PacketEncoder.encode(message)

        #expect(data.count > NetworkConstants.packetHeaderSize)

        let header = PacketHeader(data: data)
        #expect(header?.type == .mouseMove)
    }

    @Test("Encode MouseClick")
    func encodeMouseClick() throws {
        let message = MouseClick(button: .right, action: .double)
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .mouseClick)
    }

    @Test("Encode Scroll")
    func encodeScroll() throws {
        let message = Scroll(deltaX: 0, deltaY: 50, isInertia: true)
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .scroll)
    }

    @Test("Encode GyroData")
    func encodeGyroData() throws {
        let message = GyroData(
            rotationRate: Vector3(x: 0.1, y: 0.2, z: 0.3),
            attitude: Vector3(x: 0, y: 0, z: 0),
            sensitivity: 15.0
        )
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .gyroData)
    }

    @Test("Encode Handshake")
    func encodeHandshake() throws {
        let message = Handshake(
            deviceName: "Test iPhone",
            deviceID: "test-123",
            protocolVersion: UInt32(NetworkConstants.protocolVersion)
        )
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .handshake)
    }

    @Test("Encode Heartbeat")
    func encodeHeartbeat() throws {
        let message = Heartbeat()
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .heartbeat)
    }

    @Test("Encode KeyEvent")
    func encodeKeyEvent() throws {
        let message = KeyEvent(keyCode: 0, action: .press, modifiers: 0, character: "a")
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .keyEvent)
    }

    @Test("Encode MediaControl")
    func encodeMediaControl() throws {
        let message = MediaControl(command: .playPause)
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .mediaControl)
    }

    @Test("Encode WindowSnap")
    func encodeWindowSnap() throws {
        let message = WindowSnap(position: .leftHalf)
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .windowSnap)
    }

    @Test("Encode VoiceText")
    func encodeVoiceText() throws {
        let message = VoiceText(text: "Hello World", isFinal: true)
        let data = try PacketEncoder.encode(message)

        let header = PacketHeader(data: data)
        #expect(header?.type == .voiceText)
    }
}

// MARK: - PacketDecoder Tests

@Suite("PacketDecoder Tests")
struct PacketDecoderTests {
    @Test("Decode MouseMove round-trip")
    func decodeMouseMoveRoundTrip() throws {
        let original = MouseMove(deltaX: 10.5, deltaY: -5.25)
        let encoded = try PacketEncoder.encode(original)
        let decoded = try PacketDecoder.decode(encoded)

        guard case .mouseMove(let message, _) = decoded else {
            Issue.record("Expected mouseMove")
            return
        }

        #expect(message.deltaX == original.deltaX)
        #expect(message.deltaY == original.deltaY)
    }

    @Test("Decode MouseClick round-trip")
    func decodeMouseClickRoundTrip() throws {
        let original = MouseClick(button: .right, action: .double)
        let encoded = try PacketEncoder.encode(original)
        let decoded = try PacketDecoder.decode(encoded)

        guard case .mouseClick(let message, _) = decoded else {
            Issue.record("Expected mouseClick")
            return
        }

        #expect(message.button == original.button)
        #expect(message.action == original.action)
    }

    @Test("Decode Scroll round-trip")
    func decodeScrollRoundTrip() throws {
        let original = Scroll(deltaX: 0, deltaY: 50, isInertia: true)
        let encoded = try PacketEncoder.encode(original)
        let decoded = try PacketDecoder.decode(encoded)

        guard case .scroll(let message, _) = decoded else {
            Issue.record("Expected scroll")
            return
        }

        #expect(message.deltaX == original.deltaX)
        #expect(message.deltaY == original.deltaY)
        #expect(message.isInertia == original.isInertia)
    }

    @Test("Decode Handshake round-trip")
    func decodeHandshakeRoundTrip() throws {
        let original = Handshake(
            deviceName: "Test Device",
            deviceID: "device-uuid-123",
            protocolVersion: UInt32(NetworkConstants.protocolVersion)
        )
        let encoded = try PacketEncoder.encode(original)
        let decoded = try PacketDecoder.decode(encoded)

        guard case .handshake(let message, _) = decoded else {
            Issue.record("Expected handshake")
            return
        }

        #expect(message.deviceName == original.deviceName)
        #expect(message.deviceID == original.deviceID)
        #expect(message.protocolVersion == original.protocolVersion)
    }

    @Test("Decode preserves timestamp")
    func decodePreservesTimestamp() throws {
        let timestamp: UInt64 = 9_876_543_210
        let message = MouseMove(deltaX: 1, deltaY: 1)
        let header = PacketHeader(type: .mouseMove, payloadLength: 0, timestamp: timestamp)

        // Create packet manually to test timestamp
        let payload = try JSONEncoder().encode(message)
        var data = PacketHeader(type: .mouseMove, payloadLength: UInt32(payload.count), timestamp: timestamp).toData()
        data.append(payload)

        let decoded = try PacketDecoder.decode(data)
        #expect(decoded.header.timestamp == timestamp)
    }

    @Test("Invalid header throws error")
    func invalidHeaderThrowsError() throws {
        let data = Data(repeating: 0, count: 20)

        #expect(throws: PacketDecodingError.self) {
            _ = try PacketDecoder.decode(data)
        }
    }

    @Test("Payload too short throws error")
    func payloadTooShortThrowsError() throws {
        // Create header with large payload length but small actual data
        var header = PacketHeader(type: .mouseMove, payloadLength: 1000)
        let data = header.toData() // Only header, no payload

        #expect(throws: PacketDecodingError.self) {
            _ = try PacketDecoder.decode(data)
        }
    }

    @Test("parseHeader works correctly")
    func parseHeaderWorks() throws {
        let message = MouseMove(deltaX: 1, deltaY: 2)
        let encoded = try PacketEncoder.encode(message)

        let header = PacketDecoder.parseHeader(encoded)

        #expect(header != nil)
        #expect(header?.type == .mouseMove)
    }
}

// MARK: - MessageType Tests

@Suite("MessageType Tests")
struct MessageTypeTests {
    @Test("UDP message types are identified correctly")
    func udpMessageTypes() {
        #expect(MessageType.mouseMove.isUDP == true)
        #expect(MessageType.mouseClick.isUDP == true)
        #expect(MessageType.scroll.isUDP == true)
        #expect(MessageType.gyroData.isUDP == true)
        #expect(MessageType.pinch.isUDP == true)

        #expect(MessageType.mouseMove.isTCP == false)
        #expect(MessageType.mouseMove.isSystem == false)
    }

    @Test("TCP message types are identified correctly")
    func tcpMessageTypes() {
        #expect(MessageType.keyEvent.isTCP == true)
        #expect(MessageType.keyCombo.isTCP == true)
        #expect(MessageType.mediaControl.isTCP == true)
        #expect(MessageType.windowSnap.isTCP == true)
        #expect(MessageType.voiceText.isTCP == true)

        #expect(MessageType.keyEvent.isUDP == false)
        #expect(MessageType.keyEvent.isSystem == false)
    }

    @Test("System message types are identified correctly")
    func systemMessageTypes() {
        #expect(MessageType.handshake.isSystem == true)
        #expect(MessageType.heartbeat.isSystem == true)
        #expect(MessageType.disconnect.isSystem == true)
        #expect(MessageType.ack.isSystem == true)
        #expect(MessageType.error.isSystem == true)

        #expect(MessageType.handshake.isUDP == false)
        #expect(MessageType.handshake.isTCP == false)
    }
}

// MARK: - DecodedPacket Tests

@Suite("DecodedPacket Tests")
struct DecodedPacketTests {
    @Test("messageType returns correct type")
    func messageTypeReturnsCorrectType() throws {
        let mouseMove = MouseMove(deltaX: 1, deltaY: 2)
        let encoded = try PacketEncoder.encode(mouseMove)
        let decoded = try PacketDecoder.decode(encoded)

        #expect(decoded.messageType == .mouseMove)
    }

    @Test("header is accessible")
    func headerIsAccessible() throws {
        let message = Handshake(deviceName: "Test", deviceID: "123", protocolVersion: 1)
        let encoded = try PacketEncoder.encode(message)
        let decoded = try PacketDecoder.decode(encoded)

        #expect(decoded.header.type == .handshake)
        #expect(decoded.header.magic == NetworkConstants.packetMagic)
    }
}
