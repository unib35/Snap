import Foundation
import Testing
@testable import Shared

@Suite("Authenticated UDP")
struct DatagramSessionTests {
    @Test func encryptsPayloadAndSeparatesTrafficDirections() throws {
        let key = DatagramSession.makeKey()
        let client = try #require(DatagramSession(key: key, role: .client))
        let server = try #require(DatagramSession(key: key, role: .server))
        let payload = Data("private keyboard and pointer data".utf8)
        let outbound = try #require(client.seal(payload))
        let inbound = try #require(server.seal(payload))
        #expect(outbound != inbound)
        #expect(outbound.range(of: payload) == nil)
        #expect(client.open(outbound) == nil)
        #expect(server.open(inbound) == nil)
        #expect(server.open(outbound) == payload)
        #expect(client.open(inbound) == payload)
    }
    @Test func rejectsForeignModifiedAndReplayedPackets() throws {
        let key = DatagramSession.makeKey()
        let sender = try #require(DatagramSession(key: key))
        let receiver = try #require(DatagramSession(key: key, role: .server))
        let packet = try PacketEncoder.encode(MouseMove(deltaX: 4, deltaY: 2))
        let signed = try #require(sender.seal(packet))
        let foreign = try #require(DatagramSession(key: DatagramSession.makeKey()))
        #expect(foreign.open(signed) == nil)
        var modified = signed
        modified[10] ^= 1
        #expect(receiver.open(modified) == nil)
        #expect(receiver.open(signed) == packet)
        #expect(receiver.open(signed) == nil)
        #expect(receiver.open(packet) == nil)
    }

    @Test func rejectsStalePacketsAndPreviousSessions() throws {
        let key = DatagramSession.makeKey()
        let sender = try #require(DatagramSession(key: key))
        let receiver = try #require(DatagramSession(key: key, role: .server))
        let old = try #require(sender.seal(Data([1])))
        let latest = try #require(sender.seal(Data([2])))
        #expect(receiver.open(latest) == Data([2]))
        #expect(receiver.open(old) == nil)
        let nextSession = try #require(DatagramSession(key: DatagramSession.makeKey()))
        #expect(nextSession.open(latest) == nil)
        #expect(DatagramSession(key: Data()) == nil)
    }
}
