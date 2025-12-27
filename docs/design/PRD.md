# 📑 Product Requirements Document (PRD): Snap

| 프로젝트명 | **Snap** (스냅) |
| --- | --- |
| **버전** | v1.0.0 (MVP) |
| **플랫폼** | iOS (Sender) ↔ macOS (Receiver) |
| **핵심 가치** | Zero Latency, Maximum Productivity, Modern Design |
| **작성일** | 2025년 12월 27일 |

---

## 1. 프로젝트 개요 (Overview)

### 1.1 배경 (Background)

기존의 원격 제어 앱(Remote Mouse 등)은 단순히 마우스 커서를 움직이는 데 그치거나, 연결 반응 속도가 느리고(High Latency), UI가 구식입니다. 맥북 파워 유저들은 단순한 마우스 대체가 아니라, **생산성을 높여주는 도구(단축키 매크로, 윈도우 스냅)**와 **프레젠테이션 도구(레이저 포인터)**가 결합된 "All-in-One 커맨드 센터"를 필요로 합니다.

### 1.2 목표 (Goal)

* **성능:** 유선 마우스 수준의 반응 속도 구현 (UDP 통신 기반).
* **생산성:** 물리적인 키보드/트랙패드 없이도 맥북의 모든 기능을 제어.
* **확장성:** 벤토 그리드(Bento Grid) 스타일의 UI로 사용자가 원하는 기능을 직관적으로 사용.

---

## 2. 사용자 페르소나 (Target Audience)

1. **Mac Power User & Developer:**
* 책상에 앉지 않고 침대나 소파에서 맥북으로 영화를 보거나 웹 서핑을 하고 싶은 사람.
* 복잡한 단축키(빌드, 실행, 터미널 열기)를 원터치 매크로로 해결하고 싶은 개발자.


2. **Presenter & Student:**
* 발표 시 맥북을 만지지 않고 슬라이드를 넘기고, 레이저 포인터로 화면을 가리키고 싶은 사람.



---

## 3. 상세 기능 명세 (Functional Specifications)

기능은 크게 세 가지 모드(Tab)로 구분하여 제공합니다.

### 3.1 Mode 1: Essentials (기본 제어)

*가장 빠르고 빈번하게 사용되는 기능*

| 기능명 | 상세 설명 | 우선순위 | 기술 스택 |
| --- | --- | --- | --- |
| **Smart Trackpad** | • 전체 화면 터치 영역<br>

<br>• 1손가락(이동/클릭), 2손가락(스크롤/우클릭)<br>

<br>• 관성 스크롤(Inertia) 적용 | **P0** | UDP, UIKit Gesture |
| **Keyboard Bridge** | • iOS 키보드 입력을 Mac으로 실시간 전송<br>

<br>• 한/영 전환 및 특수키(Cmd, Opt, Ctrl) 지원 | **P0** | TCP, CGEvent |
| **Media Controller** | • 아이폰 물리 볼륨 버튼으로 Mac 볼륨 조절<br>

<br>• 화면 내 재생/일시정지, 이전/다음 곡 버튼 | **P0** | TCP, AppleScript |

### 3.2 Mode 2: Productivity (생산성)

*맥북의 사용성을 극대화하는 도구*

| 기능명 | 상세 설명 | 우선순위 | 기술 스택 |
| --- | --- | --- | --- |
| **Window Snap** | • 현재 창을 [좌/우/전체/중앙]으로 즉시 정렬<br>

<br>• 'Rectangle' 앱 기능 내장 | **P1** | TCP, Accessibility API |
| **App Switcher** | • Mac에서 실행 중인 앱 아이콘을 가져와 Dock 형태로 표시<br>

<br>• 터치 시 해당 앱으로 포커스 전환 | **P1** | TCP (Bi-di), NSWorkspace |
| **Macro Pad** | • 복사/붙여넣기, 스크린샷 등 자주 쓰는 단축키 모음<br>

<br>• **Bento Grid UI** 적용 | **P1** | TCP, CGEvent |

### 3.3 Mode 3: Presenter (발표 및 특수)

*아이폰의 센서를 활용한 킬러 기능*

| 기능명 | 상세 설명 | 우선순위 | 기술 스택 |
| --- | --- | --- | --- |
| **Laser Pointer** | • 아이폰을 허공에 움직여 커서 이동 (Air Mouse)<br>

<br>• 자이로스코프(Gyro) 센서 활용 | **P2** | UDP, CoreMotion |
| **Presentation Helper** | • 큰 화면 넘김 버튼 (Blind Touch 가능)<br>

<br>• 발표 타이머 및 햅틱 피드백(진동) | **P2** | TCP |
| **Voice Typing** | • 음성을 텍스트로 변환하여 Mac에 입력 | **P2** | TCP, SFSpeechRecognizer |

---

## 4. 기술 아키텍처 (Technical Architecture)

### 4.1 System Diagram

```mermaid
graph LR
    subgraph iOS [Snap iOS App]
        UI[SwiftUI Views]
        TCA[TCA Store]
        Client[Socket Client]
        Sensor[CoreMotion / Gesture]
    end

    subgraph macOS [Snap Receiver]
        Server[NWListener (Server)]
        Router[Packet Router]
        Executor[System Executor]
    end

    Sensor -->|High Freq Data| Client
    UI -->|Action| TCA
    TCA -->|Command| Client
    Client -->|UDP (Mouse/Gyro)| Server
    Client -->|TCP (Key/System)| Server
    Server -->|Parse Protobuf| Router
    Router -->|CGEvent / AX API| Executor

```

### 4.2 Network Strategy

* **Discovery:** `Bonjour` (Zero Configuration) - IP 입력 없이 자동 연결.
* **Protocol:** `Google Protocol Buffers (Protobuf)` - 데이터 패킷 경량화.
* **Transport:**
* **UDP:** 마우스 좌표, 자이로 센서 데이터 (손실 허용, 초저지연).
* **TCP:** 키보드 입력, 미디어 제어, 시스템 명령 (신뢰성 보장).



### 4.3 App Structure

* **Dependency Manager:** `Tuist`
* **Pattern:** `The Composable Architecture (TCA)`
* **Minimum Target:** iOS 17.0+, macOS 14.0+

---

## 5. UI/UX 디자인 가이드 (Design Guidelines)

* **Theme:** **Deep Dark Mode** (OLED 최적화) + **Neon Accent** (Lime Green or Cyber Blue).
* **Layout:** **Bento Grid** (둥근 모서리의 직사각형 모듈 배치).
* **Interaction:**
* 버튼 클릭 시 `UIImpactFeedbackGenerator`를 통한 묵직한 햅틱 반응.
* 연결 끊김 시 화면 전체가 흐려지며(Blur) 재연결 아이콘 표시.


* **Motion:** 모드 전환 시 부드러운 `matchedGeometryEffect` 애니메이션.

---

## 6. 개발 로드맵 (Milestones)

### Phase 1: Foundation (기반 구축)

* [x] GitHub Repo 및 Tuist 프로젝트 세팅.
* [ ] iOS ↔ macOS 소켓 연결 (Echo Test).
* [ ] Protobuf 데이터 구조 정의 및 컴파일.

### Phase 2: Essentials (기본 기능)

* [ ] 트랙패드(UDP) 구현 및 감도 조절.
* [ ] 키보드 입력(TCP) 구현.
* [ ] macOS 접근성 권한(Accessibility) 획득 로직.

### Phase 3: Productivity (생산성 기능)

* [ ] 윈도우 스냅 (Accessibility API 연구).
* [ ] 미디어 컨트롤 & 볼륨 동기화.
* [ ] 앱 스위처 (양방향 통신).

### Phase 4: Polish & Expansion (완성도)

* [ ] 자이로스코프 레이저 포인터.
* [ ] 보이스 타이핑.
* [ ] UI 디자인 적용 (Bento Grid).