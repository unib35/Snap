# Snap 개발 체크리스트

> 이 문서는 Snap 프로젝트 개발에 필요한 모든 기능, 화면, 컴포넌트를 체계적으로 정리한 체크리스트입니다.
>
> **범례**: ✅ 완료 | 🚧 진행중 | ⬜ 미착수

---

## 목차

1. [인프라 & 프로젝트 설정](#1-인프라--프로젝트-설정)
2. [공유 모듈 (Shared)](#2-공유-모듈-shared)
3. [iOS 앱 (App)](#3-ios-앱-app)
4. [macOS 앱 (MacReceiver)](#4-macos-앱-macreceiver)
5. [향후 플랫폼 확장](#5-향후-플랫폼-확장)

---

## 1. 인프라 & 프로젝트 설정

### 1.1 Tuist 설정

| 항목 | 상태 | 비고 |
| --- | --- | --- |
| Tuist.swift (Config) | ✅ | Swift 6.0, Xcode 16+ |
| Tuist/Package.swift | ✅ | TCA, SwiftProtobuf |
| Project.swift | ✅ | 3개 타겟 정의 |
| .gitignore | ✅ | Derived/, Dependencies/ 제외 |

### 1.2 타겟 구성

| 타겟 | 상태 | 플랫폼 | 의존성 |
| --- | --- | --- | --- |
| App | ✅ | iOS 17.0+ | Shared, TCA |
| AppTests | ✅ | iOS 17.0+ | App |
| MacReceiver | ✅ | macOS 14.0+ | Shared |
| MacReceiverTests | ✅ | macOS 14.0+ | MacReceiver |
| Shared | ✅ | iOS/macOS | SwiftProtobuf |

### 1.3 문서화

| 항목 | 상태 | 파일 |
| --- | --- | --- |
| CLAUDE.md | ✅ | 프로젝트 개요 및 가이드 |
| PRD | ✅ | docs/design/PRD.md |
| 프로토콜 명세 | ✅ | docs/design/ProtocolSpec.md |
| TCA 상태 트리 | ✅ | docs/design/TCAStateTree.md |
| Git 컨벤션 | ✅ | docs/git/*.md |
| Claude Commands | ✅ | .claude/commands/*.md |

### 1.4 GitHub 설정

| 항목 | 상태 | 비고 |
| --- | --- | --- |
| 저장소 생성 | ✅ | github.com/unib35/Snap |
| develop 기본 브랜치 | ✅ | |
| 이슈 라벨 | ✅ | 57개 라벨 |
| 마일스톤 | ✅ | Phase 1~4 |
| 이슈 등록 | ✅ | 14개 이슈 |

---

## 2. 공유 모듈 (Shared)

### 2.1 Protobuf 정의

| 메시지 | 상태 | 용도 |
| --- | --- | --- |
| Point, Vector3 | ⬜ | 공통 타입 |
| MouseMove | ⬜ | 마우스 이동 (UDP) |
| MouseClick | ⬜ | 마우스 클릭 (UDP) |
| Scroll | ⬜ | 스크롤 (UDP) |
| GyroData | ⬜ | 자이로스코프 (UDP) |
| KeyEvent | ⬜ | 키보드 입력 (TCP) |
| KeyCombo | ⬜ | 단축키 조합 (TCP) |
| MediaControl | ⬜ | 미디어 제어 (TCP) |
| WindowSnap | ⬜ | 윈도우 스냅 (TCP) |
| AppListRequest/Response | ⬜ | 앱 스위처 (TCP) |
| AppFocus | ⬜ | 앱 포커스 (TCP) |
| Presentation | ⬜ | 발표 제어 (TCP) |
| VoiceText | ⬜ | 음성 텍스트 (TCP) |
| Handshake | ⬜ | 연결 초기화 |
| Heartbeat | ⬜ | 연결 유지 |
| Error, Ack | ⬜ | 시스템 메시지 |

### 2.2 네트워크 레이어

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| PacketHeader | ⬜ | 공통 패킷 헤더 |
| PacketEncoder | ⬜ | Protobuf 인코딩 |
| PacketDecoder | ⬜ | Protobuf 디코딩 |
| NetworkConstants | ⬜ | 포트, 서비스 타입 등 |

---

## 3. iOS 앱 (App)

### 3.1 Core Features (TCA)

#### AppFeature (Root)

| 컴포넌트 | 상태 | 파일 |
| --- | --- | --- |
| AppFeature | ⬜ | Features/App/AppFeature.swift |
| AppView | ⬜ | Features/App/AppView.swift |

#### ConnectionFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| ConnectionFeature | ⬜ | 연결 상태 관리 |
| ConnectionView | ⬜ | 연결 UI |
| DiscoveryClient | ⬜ | Bonjour 디스커버리 |
| NetworkClient | ⬜ | TCP/UDP 통신 |

#### TabFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| TabFeature | ⬜ | 탭 상태 관리 |
| TabView | ⬜ | 탭 바 UI |

### 3.2 Mode 1: Essentials

#### TrackpadFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| TrackpadFeature | ⬜ | 트랙패드 상태 |
| TrackpadView | ⬜ | 터치 영역 UI |
| GestureRecognizer | ⬜ | 제스처 인식 |
| 1손가락 이동 | ⬜ | 마우스 이동 |
| 2손가락 스크롤 | ⬜ | 스크롤 |
| 탭 (클릭) | ⬜ | 좌클릭 |
| 2손가락 탭 | ⬜ | 우클릭 |
| 관성 스크롤 | ⬜ | Inertia |
| 감도 조절 | ⬜ | 설정 연동 |

#### KeyboardFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| KeyboardFeature | ⬜ | 키보드 상태 |
| KeyboardView | ⬜ | 입력 UI |
| ModifierBar | ⬜ | Cmd/Opt/Ctrl/Shift 버튼 |
| 텍스트 입력 | ⬜ | iOS 키보드 연동 |
| 한/영 전환 | ⬜ | |
| 특수키 | ⬜ | Return, Delete, Escape, 방향키 |

#### MediaFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| MediaFeature | ⬜ | 미디어 상태 |
| MediaView | ⬜ | 컨트롤 UI |
| 재생/일시정지 | ⬜ | |
| 이전/다음 곡 | ⬜ | |
| 볼륨 조절 | ⬜ | 슬라이더 |
| 물리 볼륨 버튼 | ⬜ | AVAudioSession |
| Now Playing | ⬜ | 현재 재생 정보 (선택) |

### 3.3 Mode 2: Productivity

#### WindowSnapFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| WindowSnapFeature | ⬜ | 윈도우 스냅 상태 |
| WindowSnapView | ⬜ | 그리드 버튼 UI |
| 좌/우 반분할 | ⬜ | |
| 전체화면 | ⬜ | |
| 4분할 | ⬜ | |
| 중앙 | ⬜ | |

#### AppSwitcherFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| AppSwitcherFeature | ⬜ | 앱 스위처 상태 |
| AppSwitcherView | ⬜ | Dock 스타일 UI |
| 앱 목록 조회 | ⬜ | 양방향 통신 |
| 앱 아이콘 표시 | ⬜ | 64x64 PNG |
| 앱 포커스 전환 | ⬜ | |

#### MacroPadFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| MacroPadFeature | ⬜ | 매크로 상태 |
| MacroPadView | ⬜ | Bento Grid UI |
| 기본 매크로 | ⬜ | 복사, 붙여넣기, 실행취소, 스크린샷 |
| 커스텀 매크로 | ⬜ | 추가/편집/삭제 |
| 매크로 실행 | ⬜ | 단축키 전송 |

### 3.4 Mode 3: Presenter

#### LaserPointerFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| LaserPointerFeature | ⬜ | 레이저 포인터 상태 |
| LaserPointerView | ⬜ | 활성화 버튼 UI |
| MotionClient | ⬜ | CoreMotion 자이로 |
| 캘리브레이션 | ⬜ | 기준점 설정 |
| 모션 → 커서 변환 | ⬜ | |
| 감도 조절 | ⬜ | |

#### PresentationFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| PresentationFeature | ⬜ | 발표 상태 |
| PresentationView | ⬜ | 큰 버튼 UI |
| 슬라이드 넘김 | ⬜ | 이전/다음 |
| 발표 타이머 | ⬜ | 카운트다운/업 |
| 햅틱 피드백 | ⬜ | 시간 알림 |
| 화면 끄기 | ⬜ | B키 전송 |

#### VoiceTypingFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| VoiceTypingFeature | ⬜ | 음성 입력 상태 |
| VoiceTypingView | ⬜ | 녹음 버튼 UI |
| SpeechClient | ⬜ | SFSpeechRecognizer |
| 권한 요청 | ⬜ | 마이크, 음성 인식 |
| 실시간 인식 | ⬜ | Interim 결과 |
| 텍스트 전송 | ⬜ | |

### 3.5 SettingsFeature

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| SettingsFeature | ⬜ | 설정 상태 |
| SettingsView | ⬜ | 설정 UI |
| 트랙패드 감도 | ⬜ | |
| 스크롤 감도 | ⬜ | |
| 레이저 감도 | ⬜ | |
| 햅틱 설정 | ⬜ | 강도 조절 |
| 테마 설정 | ⬜ | Accent Color |

### 3.6 UI/UX

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| Design System | ⬜ | 색상, 타이포그래피 |
| Deep Dark Mode | ⬜ | OLED 최적화 |
| Neon Accent | ⬜ | Lime Green / Cyber Blue |
| Bento Grid Layout | ⬜ | 둥근 모서리 모듈 |
| 햅틱 피드백 | ⬜ | UIImpactFeedbackGenerator |
| 연결 끊김 UI | ⬜ | Blur + 재연결 아이콘 |
| 모드 전환 애니메이션 | ⬜ | matchedGeometryEffect |

---

## 4. macOS 앱 (MacReceiver)

### 4.1 Core

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| MacReceiverApp | ✅ | 앱 진입점 |
| ContentView | ✅ | 메인 뷰 (플레이스홀더) |
| 메뉴바 아이콘 | ⬜ | LSUIElement |

### 4.2 네트워크

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| BonjourService | ⬜ | 서비스 광고 |
| TCPServer | ⬜ | NWListener (TCP) |
| UDPServer | ⬜ | NWListener (UDP) |
| PacketRouter | ⬜ | 패킷 분배 |
| ConnectionManager | ⬜ | 연결 상태 관리 |

### 4.3 시스템 제어

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| AccessibilityChecker | ⬜ | AXIsProcessTrusted |
| MouseController | ⬜ | CGEvent 마우스 |
| KeyboardController | ⬜ | CGEvent 키보드 |
| ScrollController | ⬜ | CGEvent 스크롤 |
| MediaController | ⬜ | 미디어 키 / AppleScript |
| WindowController | ⬜ | AXUIElement 윈도우 |
| AppController | ⬜ | NSWorkspace 앱 전환 |

### 4.4 UI

| 컴포넌트 | 상태 | 설명 |
| --- | --- | --- |
| StatusView | ⬜ | 연결 상태 표시 |
| DeviceListView | ⬜ | 연결된 디바이스 목록 |
| PermissionView | ⬜ | 권한 요청 안내 |
| PreferencesView | ⬜ | 설정 (감도 등) |

---

## 5. 향후 플랫폼 확장

### 5.1 Apple Ecosystem

| 플랫폼 | 상태 | 비고 |
| --- | --- | --- |
| macOS (Mac mini, iMac, Mac Studio) | 🚧 | 현재 개발 중 |
| Apple TV (tvOS) | ⬜ | 리모컨 기능 |
| iPad (iPadOS) | ⬜ | Receiver 역할 |
| Vision Pro (visionOS) | ⬜ | 공간 컴퓨팅 제어 |

### 5.2 Other Platforms

| 플랫폼 | 상태 | 비고 |
| --- | --- | --- |
| Windows PC | ⬜ | Windows Receiver 앱 |
| Linux / Raspberry Pi | ⬜ | Linux Receiver 앱 |
| Samsung Smart TV (Tizen) | ⬜ | TV 리모컨 |
| LG Smart TV (webOS) | ⬜ | TV 리모컨 |

### 5.3 확장 기능 (Post-MVP)

| 기능 | 상태 | 비고 |
| --- | --- | --- |
| TLS/DTLS 암호화 | ⬜ | 보안 통신 |
| 페어링 코드 인증 | ⬜ | 디바이스 인증 |
| 멀티 디바이스 | ⬜ | 여러 Receiver 동시 제어 |
| 클라우드 동기화 | ⬜ | 매크로, 설정 동기화 |
| 위젯 | ⬜ | iOS 홈 화면 위젯 |
| Shortcuts 연동 | ⬜ | Siri Shortcuts |

---

## 진행 상황 요약

| Phase | 완료 | 진행중 | 미착수 | 진행률 |
| --- | --- | --- | --- | --- |
| Phase 1: Foundation | 0 | 0 | 3 | 0% |
| Phase 2: Essentials | 0 | 0 | 4 | 0% |
| Phase 3: Productivity | 0 | 0 | 3 | 0% |
| Phase 4: Polish | 0 | 0 | 4 | 0% |

---

## 관련 문서

- [PRD](../design/PRD.md)
- [프로토콜 명세](../design/ProtocolSpec.md)
- [TCA 상태 트리](../design/TCAStateTree.md)
- [이슈 목록](https://github.com/unib35/Snap/issues)
- [마일스톤](https://github.com/unib35/Snap/milestones)
