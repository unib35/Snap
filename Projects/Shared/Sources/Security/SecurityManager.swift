import Foundation
import Network
import Security
import CryptoKit
import os

private let logger = Logger(subsystem: "com.snap.shared", category: "SecurityManager")

/// 보안 관리자 - TLS/DTLS 인증서 관리
///
/// - Note: `@unchecked Sendable` - 인증서 생성과 재조회는 `identityLock`으로 직렬화됨
public final class SecurityManager: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = SecurityManager()

    // MARK: - Constants

    private let identityLabel: String
    private let certificateLabel: String

    // MARK: - Properties

    private let identityLock = NSRecursiveLock()

    // MARK: - Initialization

    init(identityLabel: String = "Snap TLS Identity", certificateLabel: String = "Snap TLS Certificate") {
        self.identityLabel = identityLabel
        self.certificateLabel = certificateLabel
    }

    // MARK: - Public Methods

    /// 서버용 TLS Identity 가져오기 (없으면 생성)
    public func getOrCreateServerIdentity() -> SecIdentity? {
        identityLock.lock()
        defer { identityLock.unlock() }
        // 기존 Identity 검색
        if let identity = loadIdentity() {
            logger.debug("Loaded existing TLS identity")
            return identity
        }

        // 새 Identity 생성
        logger.info("Creating new TLS identity")
        return createSelfSignedIdentity()
    }

    /// 서버 인증서 가져오기
    public func getServerCertificate() -> SecCertificate? {
        guard let identity = getOrCreateServerIdentity() else {
            return nil
        }

        var certificate: SecCertificate?
        let status = SecIdentityCopyCertificate(identity, &certificate)

        guard status == errSecSuccess else {
            logger.error("Failed to copy certificate from identity: \(status)")
            return nil
        }

        return certificate
    }

    /// 인증서 데이터 내보내기 (클라이언트에 전달용)
    public func exportCertificateData() -> Data? {
        guard let certificate = getServerCertificate() else {
            return nil
        }
        return SecCertificateCopyData(certificate) as Data
    }

    /// 인증서 데이터를 SecCertificate로 변환
    public func importCertificate(from data: Data) -> SecCertificate? {
        SecCertificateCreateWithData(nil, data as CFData)
    }

    /// 신뢰된 서버 인증서 저장 (클라이언트용)
    public func saveTrustedCertificate(_ certificate: SecCertificate, for deviceID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: "Snap Trusted Certificate - \(deviceID)",
            kSecValueRef as String: certificate,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        // 기존 것 삭제 후 추가
        SecItemDelete(query as CFDictionary)
        let status = SecItemAdd(query as CFDictionary, nil)

        if status == errSecSuccess {
            logger.info("Saved trusted certificate for device: \(deviceID)")
        } else {
            logger.error("Failed to save trusted certificate: \(status)")
        }
    }

    /// 신뢰된 서버 인증서 로드 (클라이언트용)
    public func loadTrustedCertificate(for deviceID: String) -> SecCertificate? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: "Snap Trusted Certificate - \(deviceID)",
            kSecReturnRef as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let certificate = result,
              CFGetTypeID(certificate) == SecCertificateGetTypeID() else {
            return nil
        }

        // CFTypeRef를 SecCertificate로 안전하게 변환 (타입 검증 후)
        // swiftlint:disable:next force_cast
        return (certificate as! SecCertificate)
    }

    /// 신뢰된 서버 인증서 삭제 (클라이언트용)
    public func removeTrustedCertificate(for deviceID: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: "Snap Trusted Certificate - \(deviceID)"
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            logger.info("Removed trusted certificate for device: \(deviceID)")
        }
    }

    /// 모든 신뢰된 인증서 삭제
    public func removeAllTrustedCertificates() {
        // Snap Trusted Certificate로 시작하는 모든 인증서 삭제
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnAttributes as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let items = result as? [[String: Any]] else {
            return
        }

        for item in items {
            if let label = item[kSecAttrLabel as String] as? String,
               label.hasPrefix("Snap Trusted Certificate") {
                let deleteQuery: [String: Any] = [
                    kSecClass as String: kSecClassCertificate,
                    kSecAttrLabel as String: label
                ]
                SecItemDelete(deleteQuery as CFDictionary)
            }
        }
    }

    // MARK: - Private Methods

    private func loadIdentity() -> SecIdentity? {
        // Identity matching is based on the certificate's public key, not on
        // the private key label (which is not an identity query attribute).
        #if os(macOS)
        let query: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: certificateLabel,
            kSecMatchLimit as String: kSecMatchLimitAll,
            kSecReturnRef as String: true
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let certificates = result as? [SecCertificate] else { return nil }
        // An orphan certificate from an interrupted save must not hide a
        // later certificate that has a usable private key.
        for certificate in certificates {
            var identity: SecIdentity?
            if SecIdentityCreateWithCertificate(nil, certificate, &identity) == errSecSuccess {
                return identity
            }
        }
        return nil
        #else
        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecAttrLabel as String: certificateLabel,
            kSecReturnRef as String: true
        ]
        var result: CFTypeRef?
        guard SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess,
              let result, CFGetTypeID(result) == SecIdentityGetTypeID() else { return nil }
        // swiftlint:disable:next force_cast
        return (result as! SecIdentity)
        #endif
    }

    private func createSelfSignedIdentity() -> SecIdentity? {
        // 1. 개인키 생성
        guard let privateKey = createPrivateKey() else {
            logger.error("Failed to create private key")
            return nil
        }

        // 2. 자체 서명 인증서 생성
        guard let certificate = createSelfSignedCertificate(privateKey: privateKey) else {
            logger.error("Failed to create self-signed certificate")
            SecItemDelete([kSecClass: kSecClassKey, kSecValueRef: privateKey] as CFDictionary)
            return nil
        }

        // 3. Keychain에 저장
        return saveIdentity(privateKey: privateKey, certificate: certificate)
    }

    private func createPrivateKey() -> SecKey? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrIsPermanent as String: true,
            kSecAttrLabel as String: identityLabel
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            if let error = error?.takeRetainedValue() {
                logger.error("Private key generation failed: \(error.localizedDescription)")
            }
            return nil
        }

        return privateKey
    }

    private func createSelfSignedCertificate(privateKey: SecKey) -> SecCertificate? {
        guard let certificate = DERCertificateBuilder.createSelfSignedCertificate(
            privateKey: privateKey,
            commonName: "Snap Server",
            organization: "Snap App",
            validityDays: 365
        ) else {
            logger.error("Failed to create self-signed certificate using DERCertificateBuilder")
            return nil
        }

        logger.info("Successfully created self-signed certificate")
        return certificate
    }

    private func saveIdentity(privateKey: SecKey, certificate: SecCertificate) -> SecIdentity? {
        // SecItemAdd does not persist a transient SecKey reference in the
        // macOS file-based keychain. The key is made permanent at creation.
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecValueRef as String: certificate,
            kSecAttrLabel as String: certificateLabel
        ]
        let status = SecItemAdd(certQuery as CFDictionary, nil)
        guard status == errSecSuccess else {
            logger.error("Failed to save certificate: \(status)")
            SecItemDelete([kSecClass: kSecClassKey, kSecValueRef: privateKey] as CFDictionary)
            return nil
        }

        // macOS initially derives the certificate label from its subject.
        // Set our stable lookup label explicitly after adding the certificate.
        let match = [kSecClass: kSecClassCertificate, kSecValueRef: certificate] as CFDictionary
        let labelStatus = SecItemUpdate(match, [kSecAttrLabel: certificateLabel] as CFDictionary)
        guard labelStatus == errSecSuccess, let identity = loadIdentity() else {
            logger.error("Failed to reload saved TLS identity (label status: \(labelStatus))")
            SecItemDelete(match)
            SecItemDelete([kSecClass: kSecClassKey, kSecValueRef: privateKey] as CFDictionary)
            return nil
        }
        return identity
    }
}

// MARK: - TLS Configuration

public extension SecurityManager {
    /// 서버용 TLS 옵션 생성 (macOS)
    @available(macOS 10.15, iOS 13.0, *)
    func createServerTLSOptions() -> NWProtocolTLS.Options? {
        guard let identity = getOrCreateServerIdentity(),
              let secIdentity = sec_identity_create(identity) else {
            logger.error("Failed to get server identity for TLS")
            return nil
        }

        let tlsOptions = NWProtocolTLS.Options()

        sec_protocol_options_set_local_identity(
            tlsOptions.securityProtocolOptions,
            secIdentity
        )

        // TLS 1.3 요구
        sec_protocol_options_set_min_tls_protocol_version(
            tlsOptions.securityProtocolOptions,
            .TLSv13
        )

        sec_protocol_options_set_max_tls_protocol_version(
            tlsOptions.securityProtocolOptions,
            .TLSv13
        )

        return tlsOptions
    }

    /// Known-peer TLS is fail-closed: a missing pin never trusts every peer.
    func createClientTLSOptions(trustedCertificate: SecCertificate? = nil) -> NWProtocolTLS.Options {
        let pinned = trustedCertificate.map { SecCertificateCopyData($0) as Data }
        return clientTLSOptions { certificate in pinned == certificate }
    }

    /// Explicit provisional mode, exclusively for the QR-verified pairing flow.
    func createClientTLSOptions(verifier: PairingCertificateVerifier) -> NWProtocolTLS.Options {
        clientTLSOptions { verifier.verify($0) }
    }

    private func clientTLSOptions(verify: @escaping @Sendable (Data) -> Bool) -> NWProtocolTLS.Options {
        let options = NWProtocolTLS.Options()
        sec_protocol_options_set_tls_resumption_enabled(options.securityProtocolOptions, false)
        sec_protocol_options_set_tls_tickets_enabled(options.securityProtocolOptions, false)
        sec_protocol_options_set_min_tls_protocol_version(options.securityProtocolOptions, .TLSv13)
        sec_protocol_options_set_max_tls_protocol_version(options.securityProtocolOptions, .TLSv13)
        sec_protocol_options_set_verify_block(
            options.securityProtocolOptions,
            { _, trust, complete in
                let serverTrust = sec_trust_copy_ref(trust).takeRetainedValue()
                guard let chain = SecTrustCopyCertificateChain(serverTrust) as? [SecCertificate],
                      let certificate = chain.first else {
                    complete(false)
                    return
                }
                complete(verify(SecCertificateCopyData(certificate) as Data))
            },
            DispatchQueue.global()
        )
        return options
    }

    /// 서버용 DTLS 옵션 생성
    @available(macOS 10.15, iOS 13.0, *)
    func createServerDTLSOptions() -> NWProtocolTLS.Options? {
        // DTLS는 TLS와 동일한 옵션 사용
        createServerTLSOptions()
    }

    /// 클라이언트용 DTLS 옵션 생성
    @available(macOS 10.15, iOS 13.0, *)
    func createClientDTLSOptions(trustedCertificate: SecCertificate? = nil) -> NWProtocolTLS.Options {
        // DTLS는 TLS와 동일한 옵션 사용
        createClientTLSOptions(trustedCertificate: trustedCertificate)
    }

    /// PSK 기반 TLS 옵션 (인증서 없이 공유 비밀 사용)
    /// 페어링된 디바이스 간 통신에 적합
    @available(macOS 10.15, iOS 13.0, *)
    func createPSKTLSOptions(identity: String, psk: Data) -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()

        // TLS 1.3
        sec_protocol_options_set_min_tls_protocol_version(
            tlsOptions.securityProtocolOptions,
            .TLSv13
        )

        // PSK 설정은 Security framework에서 직접 지원하지 않음
        // 대안: 인증서 기반 또는 애플리케이션 레벨 암호화

        return tlsOptions
    }
}
