import Foundation
import Testing
@testable import Shared

@Suite("Secure pairing binding")
struct PairingSecurityTests {
    @Test func pinsCertificateAndRejectsReplacement() {
        let certificate = Data("certificate A".utf8)
        let other = Data("certificate B".utf8)
        let pinned = PairingCertificateVerifier(pinnedCertificate: certificate)
        #expect(!pinned.verify(other))
        #expect(pinned.certificate == nil)
        #expect(pinned.verify(certificate))
        #expect(!pinned.verify(other))
        #expect(pinned.certificate == certificate)
        let provisional = PairingCertificateVerifier(pinnedCertificate: nil)
        #expect(!provisional.verify(Data()))
        #expect(provisional.verify(certificate))
        #expect(!provisional.verify(other))
    }

    @Test func displayCodeBindsPhysicalMacToCurrentSession() throws {
        let certificate = Data("certificate A".utf8)
        let nonce = DatagramSession.makeKey()
        let secret = DatagramSession.makeKey().base64EncodedString()
        let code = PairingDisplayCode(serverID: "mac", certificate: certificate, challenge: nonce, pin: secret)
        let decoded = try PairingDisplayCode.decode(code.encoded())
        #expect(decoded == code)
        try decoded.validate(serverID: "mac", certificate: certificate, challenge: nonce)
        #expect(throws: PairingSecurityError.self) {
            try decoded.validate(serverID: "mac", certificate: Data("MITM certificate".utf8), challenge: nonce)
        }
        #expect(throws: PairingSecurityError.self) {
            try decoded.validate(serverID: "mac", certificate: certificate, challenge: DatagramSession.makeKey())
        }
        #expect(throws: PairingSecurityError.self) {
            try decoded.validate(serverID: "other", certificate: certificate, challenge: nonce)
        }
    }

    @Test func rejectsLegacyPINAndMalformedCodes() throws {
        for value in ["1234", "snap-pair:garbage", String(repeating: "a", count: 4097)] {
            #expect(throws: (any Error).self) { try PairingDisplayCode.decode(value) }
        }
        let code = PairingDisplayCode(serverID: "mac", certificate: Data([1]), challenge: DatagramSession.makeKey(), pin: "1234")
        #expect(throws: PairingSecurityError.self) { try PairingDisplayCode.decode(code.encoded()) }
    }
}

#if os(macOS)
extension PairingSecurityTests {
    @Test func keychainCredentialRoundTrip() throws {
        let store = KeychainPairingCredentialStore.shared
        let account = "regression:" + UUID().uuidString
        defer { try? store.remove(for: account) }
        #expect(try store.load(for: account) == nil)
        let first = PairingCredential(token: DatagramSession.makeKey(), serverCertificate: Data("certificate".utf8))
        try store.save(first, for: account)
        #expect(try store.load(for: account) == first)
        let replacement = PairingCredential(token: DatagramSession.makeKey())
        try store.save(replacement, for: account)
        #expect(try store.load(for: account) == replacement)
        try store.remove(for: account)
        #expect(try store.load(for: account) == nil)
    }
}
#endif
