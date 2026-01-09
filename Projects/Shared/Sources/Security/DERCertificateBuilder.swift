import Foundation
import Security
import CryptoKit

/// ASN.1 DER 인코딩을 사용한 X.509 인증서 빌더
/// iOS에서 자체 서명 인증서를 생성하기 위한 순수 Swift 구현
enum DERCertificateBuilder {
    // MARK: - ASN.1 Tags

    private enum ASN1Tag: UInt8 {
        case integer = 0x02
        case bitString = 0x03
        case octetString = 0x04
        case null = 0x05
        case objectIdentifier = 0x06
        case utf8String = 0x0C
        case printableString = 0x13
        case utcTime = 0x17
        case generalizedTime = 0x18
        case sequence = 0x30
        case set = 0x31
        // Context-specific tags
        case contextSpecific0 = 0xA0
        case contextSpecific3 = 0xA3
    }

    // MARK: - OIDs (Object Identifiers)

    /// ECDSA with SHA-256 (1.2.840.10045.4.3.2)
    private static let oidECDSAWithSHA256: [UInt8] = [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x04, 0x03, 0x02]

    /// EC Public Key (1.2.840.10045.2.1)
    private static let oidECPublicKey: [UInt8] = [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x02, 0x01]

    /// prime256v1 / secp256r1 (1.2.840.10045.3.1.7)
    private static let oidPrime256v1: [UInt8] = [0x2A, 0x86, 0x48, 0xCE, 0x3D, 0x03, 0x01, 0x07]

    /// Common Name (2.5.4.3)
    private static let oidCommonName: [UInt8] = [0x55, 0x04, 0x03]

    /// Organization (2.5.4.10)
    private static let oidOrganization: [UInt8] = [0x55, 0x04, 0x0A]

    // MARK: - Public Methods

    /// iOS에서 자체 서명 X.509 인증서 생성
    /// - Parameters:
    ///   - privateKey: ECDSA P-256 개인키 (SecKey)
    ///   - commonName: 인증서 CN (기본값: "Snap Server")
    ///   - validityDays: 유효 기간 (일, 기본값: 365)
    /// - Returns: 생성된 SecCertificate 또는 nil
    static func createSelfSignedCertificate(
        privateKey: SecKey,
        commonName: String = "Snap Server",
        organization: String = "Snap App",
        validityDays: Int = 365
    ) -> SecCertificate? {
        // 공개키 추출
        guard let publicKey = SecKeyCopyPublicKey(privateKey) else {
            return nil
        }

        // 공개키 데이터 추출 (SEC1 형식)
        guard let publicKeyData = SecKeyCopyExternalRepresentation(publicKey, nil) as Data? else {
            return nil
        }

        // 유효 기간 설정
        let notBefore = Date()
        guard let notAfter = Calendar.current.date(byAdding: .day, value: validityDays, to: notBefore) else {
            return nil
        }

        // 시리얼 넘버 생성 (랜덤 20바이트)
        var serialNumber = [UInt8](repeating: 0, count: 20)
        _ = SecRandomCopyBytes(kSecRandomDefault, serialNumber.count, &serialNumber)
        serialNumber[0] &= 0x7F // 양수로 만들기

        // TBSCertificate 생성
        let certInfo = CertificateInfo(
            serialNumber: Data(serialNumber),
            issuer: .init(commonName: commonName, organization: organization),
            subject: .init(commonName: commonName, organization: organization),
            validity: .init(notBefore: notBefore, notAfter: notAfter),
            publicKeyData: publicKeyData
        )
        let tbsCertificateData = buildTBSCertificate(info: certInfo)

        // 서명 생성
        guard let signature = signData(tbsCertificateData, with: privateKey) else {
            return nil
        }

        // 완전한 인증서 DER 생성
        let certificateDER = buildCertificate(
            tbsCertificate: tbsCertificateData,
            signature: signature
        )

        // SecCertificate 생성
        return SecCertificateCreateWithData(nil, Data(certificateDER) as CFData)
    }

    // MARK: - Certificate Info

    /// 인증서 생성에 필요한 정보를 담는 구조체
    private struct CertificateInfo {
        let serialNumber: Data
        let issuer: DistinguishedName
        let subject: DistinguishedName
        let validity: Validity
        let publicKeyData: Data

        struct DistinguishedName {
            let commonName: String
            let organization: String
        }

        struct Validity {
            let notBefore: Date
            let notAfter: Date
        }
    }

    // MARK: - Private Methods

    /// TBSCertificate 구조 생성
    private static func buildTBSCertificate(info: CertificateInfo) -> Data {
        var content = Data()

        // Version (v3 = 2, explicit tag [0])
        let versionValue = wrapInteger(Data([0x02]))
        content.append(wrapContextSpecific(tag: 0, data: versionValue))

        // Serial Number
        content.append(wrapInteger(info.serialNumber))

        // Signature Algorithm (ecdsaWithSHA256)
        content.append(buildAlgorithmIdentifier(oidECDSAWithSHA256))

        // Issuer
        content.append(buildName(commonName: info.issuer.commonName, organization: info.issuer.organization))

        // Validity
        content.append(buildValidity(notBefore: info.validity.notBefore, notAfter: info.validity.notAfter))

        // Subject
        content.append(buildName(commonName: info.subject.commonName, organization: info.subject.organization))

        // SubjectPublicKeyInfo
        content.append(buildSubjectPublicKeyInfo(publicKeyData: info.publicKeyData))

        return wrapSequence(content)
    }

    /// 완전한 Certificate 구조 생성
    private static func buildCertificate(tbsCertificate: Data, signature: Data) -> Data {
        var content = Data()

        // TBSCertificate
        content.append(tbsCertificate)

        // Signature Algorithm
        content.append(buildAlgorithmIdentifier(oidECDSAWithSHA256))

        // Signature Value (BIT STRING)
        content.append(wrapBitString(signature))

        return wrapSequence(content)
    }

    /// Algorithm Identifier 생성
    private static func buildAlgorithmIdentifier(_ oid: [UInt8]) -> Data {
        var content = Data()
        content.append(wrapOID(oid))
        return wrapSequence(content)
    }

    /// Distinguished Name 생성
    private static func buildName(commonName: String, organization: String) -> Data {
        var content = Data()

        // Organization RDN
        content.append(buildRDN(oid: oidOrganization, value: organization))

        // Common Name RDN
        content.append(buildRDN(oid: oidCommonName, value: commonName))

        return wrapSequence(content)
    }

    /// RDN (Relative Distinguished Name) 생성
    private static func buildRDN(oid: [UInt8], value: String) -> Data {
        var attrContent = Data()
        attrContent.append(wrapOID(oid))
        attrContent.append(wrapUTF8String(value))

        let attrTypeAndValue = wrapSequence(attrContent)
        return wrapSet(attrTypeAndValue)
    }

    /// Validity 구조 생성
    private static func buildValidity(notBefore: Date, notAfter: Date) -> Data {
        var content = Data()
        content.append(wrapUTCTime(notBefore))
        content.append(wrapUTCTime(notAfter))
        return wrapSequence(content)
    }

    /// SubjectPublicKeyInfo 생성
    private static func buildSubjectPublicKeyInfo(publicKeyData: Data) -> Data {
        var content = Data()

        // Algorithm (ecPublicKey + prime256v1)
        var algContent = Data()
        algContent.append(wrapOID(oidECPublicKey))
        algContent.append(wrapOID(oidPrime256v1))
        content.append(wrapSequence(algContent))

        // SubjectPublicKey (BIT STRING)
        content.append(wrapBitString(publicKeyData))

        return wrapSequence(content)
    }

    /// ECDSA-SHA256 서명 생성
    private static func signData(_ data: Data, with privateKey: SecKey) -> Data? {
        // SHA-256 해시
        let hash = SHA256.hash(data: data)
        let hashData = Data(hash)

        // ECDSA 서명
        var error: Unmanaged<CFError>?
        guard let signature = SecKeyCreateSignature(
            privateKey,
            .ecdsaSignatureMessageX962SHA256,
            data as CFData,
            &error
        ) as Data? else {
            return nil
        }

        return signature
    }

    // MARK: - ASN.1 DER Encoding Helpers

    /// 길이 인코딩
    private static func encodeLength(_ length: Int) -> Data {
        if length < 128 {
            return Data([UInt8(length)])
        } else if length < 256 {
            return Data([0x81, UInt8(length)])
        } else if length < 65_536 {
            return Data([0x82, UInt8(length >> 8), UInt8(length & 0xFF)])
        } else {
            return Data([0x83, UInt8(length >> 16), UInt8((length >> 8) & 0xFF), UInt8(length & 0xFF)])
        }
    }

    /// SEQUENCE 래핑
    private static func wrapSequence(_ data: Data) -> Data {
        var result = Data([ASN1Tag.sequence.rawValue])
        result.append(encodeLength(data.count))
        result.append(data)
        return result
    }

    /// SET 래핑
    private static func wrapSet(_ data: Data) -> Data {
        var result = Data([ASN1Tag.set.rawValue])
        result.append(encodeLength(data.count))
        result.append(data)
        return result
    }

    /// INTEGER 래핑
    private static func wrapInteger(_ data: Data) -> Data {
        var content = data

        // 양수인데 첫 바이트의 MSB가 1이면 0x00 추가
        if !content.isEmpty && (content[0] & 0x80) != 0 {
            content.insert(0x00, at: 0)
        }

        // 앞의 불필요한 0x00 제거 (단, 0x00 하나만 남기기)
        while content.count > 1 && content[0] == 0x00 && (content[1] & 0x80) == 0 {
            content.removeFirst()
        }

        var result = Data([ASN1Tag.integer.rawValue])
        result.append(encodeLength(content.count))
        result.append(content)
        return result
    }

    /// BIT STRING 래핑
    private static func wrapBitString(_ data: Data) -> Data {
        var content = Data([0x00]) // unused bits = 0
        content.append(data)

        var result = Data([ASN1Tag.bitString.rawValue])
        result.append(encodeLength(content.count))
        result.append(content)
        return result
    }

    /// OID 래핑
    private static func wrapOID(_ oid: [UInt8]) -> Data {
        var result = Data([ASN1Tag.objectIdentifier.rawValue])
        result.append(encodeLength(oid.count))
        result.append(contentsOf: oid)
        return result
    }

    /// UTF8String 래핑
    private static func wrapUTF8String(_ string: String) -> Data {
        let stringData = Data(string.utf8)
        var result = Data([ASN1Tag.utf8String.rawValue])
        result.append(encodeLength(stringData.count))
        result.append(stringData)
        return result
    }

    /// UTCTime 래핑
    private static func wrapUTCTime(_ date: Date) -> Data {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyMMddHHmmss'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        let dateString = formatter.string(from: date)
        let dateData = Data(dateString.utf8)

        var result = Data([ASN1Tag.utcTime.rawValue])
        result.append(encodeLength(dateData.count))
        result.append(dateData)
        return result
    }

    /// Context-specific tag 래핑
    private static func wrapContextSpecific(tag: UInt8, data: Data) -> Data {
        var result = Data([0xA0 + tag])
        result.append(encodeLength(data.count))
        result.append(data)
        return result
    }
}
