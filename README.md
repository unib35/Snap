# Snap

![iOS](https://img.shields.io/badge/iOS-17.0%2B-blue)
![macOS](https://img.shields.io/badge/macOS-14.0%2B-blue)
![Swift](https://img.shields.io/badge/Swift-6.0-orange)
![License](https://img.shields.io/badge/License-MIT-green)

**iOS에서 Mac을 원격 제어하는 듀얼 플랫폼 앱**

Snap은 iOS 디바이스를 Mac의 트랙패드, 키보드, 리모컨으로 변환합니다. 저지연 통신과 직관적인 인터페이스로 어디서든 Mac을 제어하세요.

## 주요 기능

### Essentials (기본 제어)
- **Smart Trackpad** - 마우스 이동, 클릭, 스크롤, 핀치 줌
- **Keyboard Bridge** - iOS 키보드로 Mac 텍스트 입력, 한/영 전환, 특수키 지원
- **Media Controller** - 재생/일시정지, 볼륨 조절, 이전/다음 곡

### Productivity (생산성)
- **Window Snap** - 창 정렬 (좌/우/전체화면/중앙 등)
- **Macro Pad** - 커스텀 단축키 매크로
- **Quick Launch** - 빠른 앱 실행 및 전환

### Presenter (발표)
- **Laser Pointer** - 자이로스코프 기반 에어 마우스
- **Presentation Helper** - 슬라이드 넘김, 타이머
- **Voice Typing** - 음성을 텍스트로 변환하여 입력

### 추가 기능
- **Shorts Remote** - YouTube Shorts 리모컨
- **Widget** - iOS 홈 화면 위젯 지원

## 요구사항

### 시스템 요구사항
- iOS 17.0 이상
- macOS 14.0 (Sonoma) 이상
- 동일한 Wi-Fi 네트워크

### 개발 환경
- Xcode 16.0 이상
- Swift 6.0
- [Tuist](https://tuist.io) (프로젝트 생성 도구)

## 설치 방법

### 1. Tuist 설치
```bash
curl -Ls https://install.tuist.io | bash
```

### 2. 프로젝트 클론
```bash
git clone https://github.com/unib35/Snap.git
cd Snap
```

### 3. 프로젝트 생성 및 빌드
```bash
# Xcode 프로젝트 생성
tuist generate

# iOS 앱 빌드
tuist build App

# macOS 앱 빌드
tuist build MacReceiver
```

### 4. 실행
1. Mac에서 **Snap Receiver** 실행
2. 시스템 환경설정 > 개인정보 보호 및 보안 > 접근성에서 권한 허용
3. iPhone에서 **Snap** 앱 실행
4. 자동으로 Mac 발견 후 연결

## 아키텍처

```
┌─────────────────┐         ┌─────────────────┐
│   iOS App       │ ──UDP──▶│   Mac Receiver  │
│   (Sender)      │ ──TCP──▶│   (Receiver)    │
│                 │◀──TCP── │                 │
│  SwiftUI + TCA  │         │  Accessibility  │
│  Bonjour        │         │  CGEvent        │
└─────────────────┘         └─────────────────┘
        │                           │
        └───────── Shared ──────────┘
              (Protobuf, Network)
```

### 프로젝트 구조
```
Snap/
├── Projects/
│   ├── App/           # iOS 앱 (SwiftUI + TCA)
│   ├── MacReceiver/   # macOS 앱
│   └── Shared/        # 공유 코드 (Network, Protocol)
├── Tuist/             # Tuist 설정
└── docs/              # 문서
```

### 네트워크 프로토콜
| 프로토콜 | 용도 | 특징 |
|---------|------|------|
| UDP | 마우스, 자이로 | 저지연, 손실 허용 |
| TCP | 키보드, 시스템 명령 | 신뢰성 보장 |
| Bonjour | 디바이스 발견 | Zero-config |
| Protobuf | 패킷 직렬화 | 바이너리, 고효율 |

### 보안
- TLS 1.3 (TCP 연결)
- DTLS (UDP 연결)
- 페어링 코드 인증

## 기여 방법

### 브랜치 컨벤션
```
{type}/{description}  (kebab-case)
```
예시: `feat/add-gesture-recognition`, `fix/connection-timeout`

### 커밋 컨벤션
```
[Type]: 제목

- 세부 내용

Close #이슈번호
```
Types: `[Feat]`, `[Fix]`, `[Refactor]`, `[Design]`, `[Docs]`, `[Test]`, `[Perf]`

### 워크플로우
1. `develop` 브랜치에서 feature 브랜치 생성
2. 작업 후 PR 생성
3. 코드 리뷰 후 스쿼시 머지

## 라이선스

MIT License - 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## 연락처

- GitHub Issues: [https://github.com/unib35/Snap/issues](https://github.com/unib35/Snap/issues)
