import CryptoKit
import Foundation

/// Per-connection authenticated encryption. Directional keys prevent nonce
/// reuse when both peers start their counters at one. The root key is fresh
/// for each accepted session and is transferred only over pinned TLS.
public final class DatagramSession: @unchecked Sendable {
    public enum Role: Sendable { case client, server }
    public let id = UUID()
    private let sendingKey: SymmetricKey
    private let receivingKey: SymmetricKey
    private let lock = NSLock()
    private var outgoingSequence: UInt64 = 0
    private var incomingSequence: UInt64 = 0
    private static let context = Data("Snap UDP v3".utf8)
    private static let noncePrefix = Data([0x53, 0x4e, 0x00, 0x03])

    public static func makeKey() -> Data {
        SymmetricKey(size: .bits256).withUnsafeBytes { Data($0) }
    }

    public init?(key: Data, role: Role = .client) {
        guard key.count == 32 else { return nil }
        let rootKey = SymmetricKey(data: key)
        let clientKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: rootKey,
            salt: Self.context,
            info: Data("client-to-server".utf8),
            outputByteCount: 32
        )
        let serverKey = HKDF<SHA256>.deriveKey(
            inputKeyMaterial: rootKey,
            salt: Self.context,
            info: Data("server-to-client".utf8),
            outputByteCount: 32
        )
        sendingKey = role == .client ? clientKey : serverKey
        receivingKey = role == .client ? serverKey : clientKey
    }

    public func seal(_ payload: Data) -> Data? {
        lock.withLock {
            guard outgoingSequence < UInt64.max else { return nil }
            outgoingSequence += 1
            var sequence = outgoingSequence.bigEndian
            var nonce = Self.noncePrefix
            withUnsafeBytes(of: &sequence) { nonce.append(contentsOf: $0) }
            guard let nonce = try? AES.GCM.Nonce(data: nonce),
                  let box = try? AES.GCM.seal(payload, using: sendingKey, nonce: nonce, authenticating: Self.context) else {
                return nil
            }
            return box.combined
        }
    }

    public func open(_ datagram: Data) -> Data? {
        guard datagram.count >= 28, datagram.prefix(4) == Self.noncePrefix,
              let box = try? AES.GCM.SealedBox(combined: datagram),
              let payload = try? AES.GCM.open(box, using: receivingKey, authenticating: Self.context) else { return nil }
        let sequence = datagram.withUnsafeBytes { UInt64(bigEndian: $0.loadUnaligned(fromByteOffset: 4, as: UInt64.self)) }
        return lock.withLock {
            guard sequence > incomingSequence else { return nil }
            incomingSequence = sequence
            return payload
        }
    }
}
