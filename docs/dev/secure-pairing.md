# QR 페어링과 암호화 연결

2026-09-12 · [GitHub #152](https://github.com/unib35/Snap/issues/152)

## 사용 방법과 기존 연결 전환

1. iOS 앱과 MacReceiver를 함께 업데이트합니다. 프로토콜 v3는 이전 버전과 직접 연결되지 않습니다.
2. iOS 연결 목록에서 Mac을 선택합니다. Mac에 표시된 QR 코드를 iPhone으로 스캔합니다.
3. 카메라를 사용할 수 없으면 Mac의 **코드 복사**와 iOS의 **붙여넣기**를 사용합니다. 직접 보고 있는 Mac에서 복사한 코드만 사용합니다.
4. 코드는 60초 동안 해당 연결에서만 유효합니다. 만료되거나 취소했다면 다시 연결해 새 코드를 받습니다.
5. 이후에는 저장된 인증서와 토큰으로 재연결합니다. 이전 버전의 신뢰 기기 ID만 남아 있는 경우에도 QR 확인을 한 번 거칩니다.

Mac 재설치 등으로 인증서가 바뀌면 연결을 거부합니다. Mac이 맞는지 직접 확인한 후 iOS 연결 목록의 기기 메뉴에서 연결 정보를 삭제하고 다시 페어링합니다. 오류 발생 시 자동으로 인증서를 교체하거나 평문 연결로 전환하지 않습니다.

## 구현

- TCP 제어 채널은 TLS 1.3을 필수로 사용합니다. 최초 연결은 아직 신뢰하지 않는 인증서를 관찰하는 단계이며, QR의 인증서 해시·Mac ID·요청 nonce가 현재 TLS 연결과 일치해야 일회성 비밀을 보냅니다.
- QR에는 32바이트 무작위 일회성 비밀이 포함됩니다. 기존 4자리 PIN은 사용하지 않습니다. Mac은 연결·기기 ID·nonce·비밀·만료 시각을 확인합니다.
- 성공하면 서버가 새 32바이트 토큰을 발급합니다. 재연결에는 기기 ID와 토큰이 모두 필요합니다. 토큰과 고정 인증서는 Keychain에 저장하며 iCloud 동기화를 사용하지 않습니다.
- UDP는 매 연결마다 새 키를 받고 HKDF로 송수신 키를 분리합니다. AES-GCM으로 본문을 암호화·인증하며, 방향 반사·변조·중복·과거 시퀀스를 거부합니다. 역순으로 도착한 오래된 이동 데이터도 폐기합니다.
- macOS 개인키는 생성 시점에 영구 저장합니다. 인증서 추가 후 검색 라벨을 명시적으로 갱신하고 Identity를 재조회합니다. 개인키 없이 남은 이전 인증서가 정상 인증서 조회를 가리지 않도록 확인합니다. 임시 SecKey를 나중에 `SecItemAdd`하는 기존 방식은 실제 macOS 테스트에서 Identity를 구성하지 못했습니다.
- 인증서 검증 실패가 Network.framework의 `.waiting(.tls)`로 보고되어도 즉시 종료합니다. 일반 연결 타임아웃으로 숨기지 않습니다.

정확한 메시지와 wire format은 [프로토콜 명세](../design/ProtocolSpec.md)에 기록합니다. 인증서 고정 방식은 공인 CA 기반 서버 인증과 별개이며, 최초 신뢰는 사용자가 직접 확인하는 Mac 화면에서 얻습니다.

## 검증

- iOS AppTests: 121개 통과 (iPhone 17 시뮬레이터, iOS 26.5).
- 공유 모듈·macOS 핵심 테스트: 75개 통과.
- 실제 루프백 TLS: Identity 저장·재조회, 고정 인증서 연결과 패킷 전달, 인증서 정보 누락·불일치 거부 확인.
- 실제 Keychain: 테스트 전용 계정의 저장·재조회·갱신·삭제 확인. TLS 테스트는 고유 라벨로 만든 개인키·인증서를 정리합니다.
- 실제 TCP 분할·EOF, UDP 연속 수신, AES-GCM 변조·재전송, 기기 ID 사칭, 다른 세션의 페어링 응답을 검증합니다. 입력 테스트는 CGEvent를 캡처하며 실제 키보드·마우스 입력을 발생시키지 않습니다.
- Xcode 26.5 / Tuist 4.71.0, iOS·macOS Debug 빌드 성공. SwiftLint 위반 0개.

핵심 테스트는 MacReceiver 앱을 실행하지 않고 다음 명령으로 재현합니다.

```bash
python3 scripts/test-core.py
```

이 스크립트는 임시 SwiftPM 패키지에서 Shared와 수신기의 네트워크·입력 코드를 컴파일하며 종료 후 임시 파일을 정리합니다. 앱 전체 검증에는 `tuist generate --no-open` 후 `Snap.xcworkspace`의 App 테스트와 MacReceiver 빌드도 실행합니다.

## 별도 실기기 확인 항목

- iPhone 카메라로 실제 Mac QR 스캔, 복사·붙여넣기, 취소·만료 후 재연결.
- 양쪽 앱 재실행 후 자동 재연결, 인증서 변경 후 수동 재페어링.
- 코드 서명된 앱의 Keychain 접근, macOS 접근성 권한과 실제 입력, 절전 복귀.
- 배포용 Archive는 이번 개발 빌드 검증에 포함하지 않았습니다.

## Xcode 링크 오류

`swift-sharing_Sharing.bundle` 누락 당시 로그에는 App·Shared·SnapWidget 3개 타깃만 있었고 외부 패키지 타깃이 빠져 있었습니다. 저장소 루트의 **Snap.xcworkspace**로 빌드하면 swift-sharing 리소스 번들 생성과 TCA 의존성이 포함됩니다. 사용자가 오류를 본 DerivedData 경로에서도 워크스페이스 빌드를 확인했습니다.

관련 Apple 자료: [macOS Keychain 구현 차이](https://developer.apple.com/documentation/technotes/tn3137-on-mac-keychains), [인증서 저장](https://developer.apple.com/documentation/security/storing-a-certificate-in-the-keychain).
