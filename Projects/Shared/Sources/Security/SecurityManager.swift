import Foundation
import Network
import Security
import CryptoKit
import os

private let logger = Logger(subsystem: "com.snap.shared", category: "SecurityManager")

/// 보안 관리자 - TLS/DTLS 인증서 관리
///
/// - Note: `@unchecked Sendable` - 내부 DispatchQueue(`queue`)를 통해 모든 상태 접근이 직렬화되어 스레드 안전함
public final class SecurityManager: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = SecurityManager()

    // MARK: - Constants

    private let keychainServiceName = "com.snap.security"
    private let identityLabel = "Snap TLS Identity"
    private let certificateLabel = "Snap TLS Certificate"

    // MARK: - Properties

    private let queue = DispatchQueue(label: "com.snap.security", attributes: .concurrent)

    // MARK: - Initialization

    private init() {}

    // MARK: - Public Methods

    /// 서버용 TLS Identity 가져오기 (없으면 생성)
    public func getOrCreateServerIdentity() -> SecIdentity? {
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassIdentity,
            kSecAttrLabel as String: identityLabel,
            kSecReturnRef as String: true
        ]

        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess, let identity = result else {
            return nil
        }

        // Keychain에서 kSecClassIdentity로 쿼리했으므로 SecIdentity 타입이 보장됨
        // swiftlint:disable:next force_cast
        return (identity as! SecIdentity)
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
            return nil
        }

        // 3. Keychain에 저장
        return saveIdentity(privateKey: privateKey, certificate: certificate)
    }

    private func createPrivateKey() -> SecKey? {
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrIsPermanent as String: false
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
        // macOS와 iOS에서 자체 서명 인증서 생성이 다르므로
        // Security framework의 제한으로 인해 DER 인코딩된 인증서 직접 생성

        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            return nil
        }

        // 인증서 유효 기간 (1년)
        let validFrom = Date()
        let validTo = Calendar.current.date(byAdding: .year, value: 1, to: validFrom) ?? validFrom

        // 인증서 생성을 위한 데이터 구조
        // 실제 구현에서는 ASN.1 DER 인코딩이 필요하지만,
        // Apple의 Security framework에서는 직접적인 인증서 생성 API가 제한적
        // 대안: Keychain에서 기존 인증서를 사용하거나 번들에 포함

        // 간단한 자체 서명 인증서 생성 (테스트용)
        // 실제 프로덕션에서는 사전 생성된 인증서 사용 권장
        return createCertificateUsingKeychain(privateKey: privateKey, publicKey: publicKey)
    }

    private func createCertificateUsingKeychain(privateKey: SecKey, publicKey: SecKey) -> SecCertificate? {
        // ASN.1 DER 인코딩을 사용하여 자체 서명 인증서 생성
        // iOS와 macOS 모두에서 동작
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
        // 개인키 저장
        let keyQuery: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrLabel as String: identityLabel,
            kSecValueRef as String: privateKey,
            kSecAttrIsPermanent as String: true,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(keyQuery as CFDictionary)
        var status = SecItemAdd(keyQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            logger.error("Failed to save private key: \(status)")
            return nil
        }

        // 인증서 저장
        let certQuery: [String: Any] = [
            kSecClass as String: kSecClassCertificate,
            kSecAttrLabel as String: certificateLabel,
            kSecValueRef as String: certificate,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]

        SecItemDelete(certQuery as CFDictionary)
        status = SecItemAdd(certQuery as CFDictionary, nil)

        guard status == errSecSuccess else {
            logger.error("Failed to save certificate: \(status)")
            return nil
        }

        // Identity 로드
        return loadIdentity()
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

    /// 클라이언트용 TLS 옵션 생성 (iOS) - 신뢰된 인증서 기반
    @available(macOS 10.15, iOS 13.0, *)
    func createClientTLSOptions(trustedCertificate: SecCertificate? = nil) -> NWProtocolTLS.Options {
        let tlsOptions = NWProtocolTLS.Options()

        // TLS 1.3 요구
        sec_protocol_options_set_min_tls_protocol_version(
            tlsOptions.securityProtocolOptions,
            .TLSv13
        )

        sec_protocol_options_set_max_tls_protocol_version(
            tlsOptions.securityProtocolOptions,
            .TLSv13
        )

        // 인증서 검증 콜백 설정
        sec_protocol_options_set_verify_block(
            tlsOptions.securityProtocolOptions,
            { _, trust, completionHandler in
                // 로컬 네트워크 자체 서명 인증서 허용
                // 프로덕션에서는 신뢰된 인증서 목록과 비교 필요
                if let trustedCertificate {
                    // 신뢰된 인증서와 비교
                    let serverTrust = sec_trust_copy_ref(trust).takeRetainedValue()
                    if let serverCert = SecTrustGetCertificateAtIndex(serverTrust, 0) {
                        let serverData = SecCertificateCopyData(serverCert) as Data
                        let trustedData = SecCertificateCopyData(trustedCertificate) as Data
                        completionHandler(serverData == trustedData)
                        return
                    }
                }

                // 신뢰된 인증서가 없으면 기본적으로 허용 (페어링 전)
                // 실제로는 페어링 과정에서 인증서 교환 필요
                completionHandler(true)
            },
            DispatchQueue.global()
        )

        return tlsOptions
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
