import CryptoKit
import Foundation
import Security

public struct PairingCredential: Codable, Sendable, Equatable {
    public let token: Data
    public let serverCertificate: Data?

    public init(token: Data, serverCertificate: Data? = nil) {
        self.token = token
        self.serverCertificate = serverCertificate
    }

    public func matches(_ candidate: Data) -> Bool {
        guard token.count == 32, candidate.count == 32 else { return false }
        let context = Data("Snap pairing credential v3".utf8)
        let proof = HMAC<SHA256>.authenticationCode(for: context, using: SymmetricKey(data: candidate))
        return HMAC<SHA256>.isValidAuthenticationCode(proof, authenticating: context, using: SymmetricKey(data: token))
    }
}

public protocol PairingCredentialStore: Sendable {
    func load(for account: String) throws -> PairingCredential?
    func save(_ credential: PairingCredential, for account: String) throws
    func remove(for account: String) throws
}

public enum PairingSecurityError: Error, LocalizedError, Sendable {
    case invalidCode
    case certificateMismatch
    case missingCredentials
    case keychain(OSStatus)

    public var errorDescription: String? {
        switch self {
        case .invalidCode: return "이 연결의 페어링 코드가 아닙니다. Mac에 표시된 코드를 다시 스캔하세요."
        case .certificateMismatch: return "Mac의 인증서가 일치하지 않아 연결을 중단했습니다."
        case .missingCredentials: return "보안 연결 정보를 확인할 수 없습니다. 다시 페어링하세요."
        case .keychain: return "안전한 저장소에 연결 정보를 저장하거나 읽을 수 없습니다."
        }
    }
}

/// Tokens and pinned certificates are local to this device, never iCloud-synced.
public final class KeychainPairingCredentialStore: PairingCredentialStore, @unchecked Sendable {
    public static let shared = KeychainPairingCredentialStore()
    private let lock = NSLock()
    private let service = "com.snap.pairing.v3"

    private init() {}

    public func load(for account: String) throws -> PairingCredential? {
        try lock.withLock {
            var query = baseQuery(account)
            query[kSecReturnData as String] = true
            query[kSecMatchLimit as String] = kSecMatchLimitOne
            var result: CFTypeRef?
            let status = SecItemCopyMatching(query as CFDictionary, &result)
            if status == errSecItemNotFound { return nil }
            guard status == errSecSuccess, let data = result as? Data else {
                throw PairingSecurityError.keychain(status)
            }
            let credential = try JSONDecoder().decode(PairingCredential.self, from: data)
            guard credential.token.count == 32 else { throw PairingSecurityError.missingCredentials }
            return credential
        }
    }

    public func save(_ credential: PairingCredential, for account: String) throws {
        try lock.withLock {
            guard credential.token.count == 32 else { throw PairingSecurityError.missingCredentials }
            let data = try JSONEncoder().encode(credential)
            let query = baseQuery(account)
            let update = [kSecValueData as String: data]
            var status = SecItemUpdate(query as CFDictionary, update as CFDictionary)
            if status == errSecItemNotFound {
                var item = query
                item[kSecValueData as String] = data
                item[kSecAttrAccessible as String] = kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
                status = SecItemAdd(item as CFDictionary, nil)
            }
            guard status == errSecSuccess else { throw PairingSecurityError.keychain(status) }
        }
    }

    private func baseQuery(_ account: String) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
    }

    public func remove(for account: String) throws {
        try lock.withLock {
            let status = SecItemDelete(baseQuery(account) as CFDictionary)
            guard status == errSecSuccess || status == errSecItemNotFound else {
                throw PairingSecurityError.keychain(status)
            }
        }
    }
}

/// An unpaired TLS peer is provisional: it must match an out-of-band QR code
/// before PINs, tokens, input, or persisted trust may be sent to it.
public final class PairingCertificateVerifier: @unchecked Sendable {
    private let pinnedCertificate: Data?
    private let lock = NSLock()
    private var observed: Data?

    public init(pinnedCertificate: Data?) { self.pinnedCertificate = pinnedCertificate }
    public var certificate: Data? { lock.withLock { observed } }

    public func verify(_ certificate: Data) -> Bool {
        lock.withLock {
            guard !certificate.isEmpty,
                  pinnedCertificate == nil || pinnedCertificate == certificate else { return false }
            // A verifier belongs to exactly one transport connection.
            guard observed == nil || observed == certificate else { return false }
            observed = certificate
            return true
        }
    }
}

/// Transferred only via the Mac display or an explicit user copy/paste action.
/// The PIN is never included in PairingChallenge or in logs.
public struct PairingDisplayCode: Codable, Sendable, Equatable {
    public let version: Int
    public let serverID: String
    public let certificateDigest: Data
    public let challenge: Data
    public let pin: String

    public init(serverID: String, certificate: Data, challenge: Data, pin: String) {
        version = 3
        self.serverID = serverID
        certificateDigest = Data(SHA256.hash(data: certificate))
        self.challenge = challenge
        self.pin = pin
    }

    public func encoded() throws -> String {
        "snap-pair:" + (try JSONEncoder().encode(self)).base64EncodedString()
    }

    public static func decode(_ value: String) throws -> Self {
        guard value.utf8.count <= 4096, value.hasPrefix("snap-pair:"),
              let data = Data(base64Encoded: String(value.dropFirst("snap-pair:".count))) else {
            throw PairingSecurityError.invalidCode
        }
        let code = try JSONDecoder().decode(Self.self, from: data)
        guard code.version == 3, !code.serverID.isEmpty, code.serverID.utf8.count <= 256,
              code.challenge.count == 32, code.certificateDigest.count == 32,
              Data(base64Encoded: code.pin)?.count == 32 else {
            throw PairingSecurityError.invalidCode
        }
        return code
    }

    public func validate(serverID: String, certificate: Data, challenge: Data) throws {
        guard self.serverID == serverID, self.challenge == challenge else {
            throw PairingSecurityError.invalidCode
        }
        guard certificateDigest == Data(SHA256.hash(data: certificate)) else {
            throw PairingSecurityError.certificateMismatch
        }
    }
}
