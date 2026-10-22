import Foundation
import Network
import Security
import Testing
@testable import Shared

private final class TransportSpy: TCPConnectionDelegate, UDPSocketDelegate, @unchecked Sendable {
    private let lock = NSLock()
    private var received = 0
    private var ready = false
    private var ended = 0
    private var accepted: TCPConnection?
    private var lastState = "not accepted"
    private var listening = false
    var isListening: Bool { lock.withLock { listening } }
    func listenerReady() { lock.withLock { listening = true } }
    var diagnostic: String { lock.withLock { lastState } }
    func record(_ state: String) { lock.withLock { lastState = state } }
    var count: Int { lock.withLock { received } }
    var isReady: Bool { lock.withLock { ready } }
    var disconnectCount: Int { lock.withLock { ended } }
    func accept(_ raw: NWConnection, secure: Bool = false) {
        let connection = TCPConnection(connection: raw, isSecure: secure)
        record("accepted")
        lock.withLock { accepted = connection }
        connection.delegate = self
        connection.connect()
    }
    func close() { lock.withLock { accepted?.disconnect(); accepted = nil } }
    func tcpConnectionDidConnect(_ connection: TCPConnection) { lock.withLock { ready = true } }
    func tcpConnectionDidDisconnect(_ connection: TCPConnection, error: Error?) {
        lock.withLock { ended += 1; lastState = "disconnected: \(String(describing: error))" }
    }
    func tcpConnection(_ connection: TCPConnection, didReceive packet: DecodedPacket) { lock.withLock { received += 1 } }
    func udpSocketDidReady(_ socket: UDPSocket) { lock.withLock { ready = true } }
    func udpSocket(_ socket: UDPSocket, didReceive packet: DecodedPacket, from endpoint: NWEndpoint, sessionID: UUID) {
        lock.withLock { received += 1 }
    }
    func udpSocket(_ socket: UDPSocket, didFailWithError error: Error) {}
}

private enum TransportTestError: Error { case timeout(String) }

private func eventually(_ stage: String = "condition", _ condition: @Sendable () -> Bool) async throws {
    let deadline = ContinuousClock.now + .seconds(5)
    while !condition() {
        guard ContinuousClock.now < deadline else { throw TransportTestError.timeout(stage) }
        try await Task.sleep(for: .milliseconds(10))
    }
}

private func send(_ data: Data, to connection: NWConnection, final: Bool = false) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
        connection.send(
            content: data,
            contentContext: final ? .finalMessage : .defaultMessage,
            isComplete: true,
            completion: .contentProcessed { error in
                if let error { continuation.resume(throwing: error) } else { continuation.resume() }
            }
        )
    }
}

@Suite("Loopback transport", .serialized)
struct TransportTests {
    @Test func receivesFragmentedTCPFramesBeforeEOF() async throws {
        let spy = TransportSpy()
        let parameters = NWParameters.tcp
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        let listener = try NWListener(using: parameters, on: .any)
        listener.stateUpdateHandler = { state in
            if case .ready = state { spy.listenerReady() }
        }
        listener.newConnectionHandler = { spy.accept($0) }
        listener.start(queue: DispatchQueue(label: "snap.test.listener"))
        defer { listener.cancel(); spy.close() }
        try await eventually("listener ready") { spy.isListening }
        let port = try #require(listener.port)
        let client = NWConnection(host: "127.0.0.1", port: port, using: .tcp)
        client.stateUpdateHandler = { spy.record("client: \($0)") }
        client.start(queue: DispatchQueue(label: "snap.test.client"))
        defer { client.cancel() }
        do {
            try await eventually("TCP ready") { spy.isReady }
        } catch {
            Issue.record("TCP connection state: \(spy.diagnostic)")
            throw error
        }
        let packet = try PacketEncoder.encode(KeyEvent(keyCode: 36))
        try await send(Data(packet.prefix(7)), to: client)
        var remainder = Data(packet.dropFirst(7))
        remainder.append(packet)
        try await send(remainder, to: client, final: true)
        try await eventually("TCP EOF (received \(spy.count) packets)") { spy.disconnectCount == 1 }
        #expect(spy.count == 2)
    }

    @Test func receivesMultipleUDPDatagramsAndRejectsUnsignedTraffic() async throws {
        let spy = TransportSpy()
        let receiver = UDPSocket(port: 0, role: .server)
        let key = DatagramSession.makeKey()
        receiver.setSessionKey(key)
        receiver.delegate = spy
        try receiver.listen()
        defer { receiver.close() }
        try await eventually { spy.isReady }
        let port = try #require(receiver.localPort)
        let nwPort = try #require(NWEndpoint.Port(rawValue: port))
        let client = NWConnection(host: "127.0.0.1", port: nwPort, using: .udp)
        client.start(queue: DispatchQueue(label: "snap.test.udp.client"))
        defer { client.cancel() }
        let sender = try #require(DatagramSession(key: key))
        let packet = try PacketEncoder.encode(MouseMove(deltaX: 5, deltaY: 6))
        try await send(packet, to: client)
        let first = try #require(sender.seal(packet))
        try await send(first, to: client)
        try await send(first, to: client)
        try await send(try #require(sender.seal(packet)), to: client)
        try await send(try #require(sender.seal(packet)), to: client)
        try await eventually { spy.count >= 3 }
        #expect(spy.count == 3)
    }
}

#if os(macOS)
extension TransportTests {
    @Test func tlsIdentityReloadsAndRejectsWrongOrMissingPin() async throws {
        let label = "Snap regression " + UUID().uuidString
        let manager = SecurityManager(identityLabel: label + " key", certificateLabel: label + " cert")
        defer {
            SecItemDelete([kSecClass: kSecClassKey, kSecAttrLabel: label + " key"] as CFDictionary)
            SecItemDelete([kSecClass: kSecClassCertificate, kSecAttrLabel: label + " cert"] as CFDictionary)
        }
        // Simulate a previous interrupted save that left a certificate but
        // no permanent private key under the same lookup label.
        let orphanKey = try #require(SecKeyCreateRandomKey([
            kSecAttrKeyType: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits: 256,
            kSecAttrIsPermanent: false
        ] as CFDictionary, nil))
        let orphan = try #require(DERCertificateBuilder.createSelfSignedCertificate(privateKey: orphanKey))
        let orphanQuery = [kSecClass: kSecClassCertificate, kSecValueRef: orphan] as CFDictionary
        #expect(SecItemAdd(orphanQuery, nil) == errSecSuccess)
        defer { SecItemDelete(orphanQuery) }
        #expect(SecItemUpdate(orphanQuery, [kSecAttrLabel: label + " cert"] as CFDictionary) == errSecSuccess)
        _ = try #require(manager.getOrCreateServerIdentity())
        let certificate = try #require(manager.getServerCertificate())
        let data = SecCertificateCopyData(certificate) as Data
        #expect(data != SecCertificateCopyData(orphan) as Data)
        let reloaded = SecurityManager(identityLabel: label + " key", certificateLabel: label + " cert")
        #expect(reloaded.exportCertificateData() == data)
        let options = try #require(manager.createServerTLSOptions())
        let parameters = NWParameters(tls: options)
        parameters.requiredLocalEndpoint = .hostPort(host: "127.0.0.1", port: .any)
        let listener = try NWListener(using: parameters, on: .any)
        let spy = TransportSpy()
        listener.stateUpdateHandler = { if case .ready = $0 { spy.listenerReady() } }
        listener.newConnectionHandler = { spy.accept($0, secure: true) }
        listener.start(queue: DispatchQueue(label: "snap.test.tls.listener"))
        defer { listener.cancel(); spy.close() }
        try await eventually("TLS listener") { spy.isListening }
        let port = try #require(listener.port)
        let good = NWConnection(
            host: "127.0.0.1",
            port: port,
            using: NWParameters(tls: manager.createClientTLSOptions(trustedCertificate: certificate))
        )
        good.start(queue: DispatchQueue(label: "snap.test.tls.good"))
        defer { good.cancel() }
        try await eventually("pinned TLS") { spy.isReady }
        try await send(try PacketEncoder.encode(KeyEvent(keyCode: 36)), to: good)
        try await eventually("TLS frame") { spy.count == 1 }
        good.cancel()
        try await eventually("TLS disconnect") { spy.disconnectCount == 1 }
        for options in [
            manager.createClientTLSOptions(),
            manager.createClientTLSOptions(verifier: PairingCertificateVerifier(pinnedCertificate: Data("wrong certificate".utf8)))
        ] {
            let rejected = TransportSpy()
            let client = NWConnection(host: "127.0.0.1", port: port, using: NWParameters(tls: options))
            client.stateUpdateHandler = { state in
                switch state {
                case .failed(.tls), .waiting(.tls): rejected.record("rejected")
                case .ready: rejected.record("unexpectedly ready")
                default: break
                }
            }
            client.start(queue: DispatchQueue(label: "snap.test.tls.rejected"))
            defer { client.cancel() }
            try await eventually("TLS rejection") { rejected.diagnostic == "rejected" }
        }
    }
}
#endif
