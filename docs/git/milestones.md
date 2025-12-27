# GitHub 마일스톤 가이드

이 문서는 Snap 프로젝트에서 사용하는 GitHub 마일스톤을 정의합니다.

---

## 마일스톤 구조

마이크로 마일스톤 전략을 사용하여 개발 단계를 세분화합니다.

### Phase 1: Foundation

| 마일스톤 | 설명 | 주요 작업 |
| --- | --- | --- |
| **1.1 Shared 모듈** | 공통 모듈 구현 | Protobuf 정의, 네트워크 레이어 |
| **1.2 iOS 앱 기본 구조** | TCA 앱 구조 | AppFeature, TabFeature |
| **1.3 macOS 서버 구현** | 수신 서버 | TCP/UDP 서버, 메뉴바 앱 |
| **1.4 디바이스 연결** | 연결 수립 | Bonjour, Handshake, 연결 관리 |

### Phase 2: Essentials

| 마일스톤 | 설명 | 주요 작업 |
| --- | --- | --- |
| **2.1 트랙패드** | 마우스 제어 | 이동, 클릭, 스크롤, 감도 조절 |
| **2.2 키보드** | 텍스트 입력 | 키 입력, 한/영, 특수키 |
| **2.3 미디어 컨트롤** | 미디어 제어 | 재생/정지, 볼륨, 이전/다음 |
| **2.4 macOS 접근성** | 시스템 제어 | 접근성 권한, CGEvent |

### Phase 3: Productivity

| 마일스톤 | 설명 | 주요 작업 |
| --- | --- | --- |
| **3.1 윈도우 스냅** | 윈도우 관리 | AXUIElement, 10가지 스냅 |
| **3.2 앱 스위처** | 앱 전환 | 앱 목록, 아이콘, 포커스 |
| **3.3 매크로 패드** | 매크로 기능 | Bento Grid, 커스텀 매크로 |

### Phase 4: Polish & Expansion

| 마일스톤 | 설명 | 주요 작업 |
| --- | --- | --- |
| **4.1 레이저 포인터** | Air Mouse | CoreMotion, 자이로 제어 |
| **4.2 프레젠테이션 헬퍼** | 발표 모드 | 슬라이드 제어, 타이머 |
| **4.3 음성 타이핑** | 음성 입력 | SFSpeechRecognizer |
| **4.4 UI/UX 디자인** | 디자인 적용 | Bento Grid, Deep Dark Mode |
| **4.5 플랫폼 확장** | 멀티 플랫폼 | Apple TV, Windows, Linux, Smart TV |

---

## 마일스톤 상세

### 1.1 Shared 모듈

> Protobuf 데이터 구조 및 네트워크 레이어 구현

**완료 조건:**
- [ ] Protobuf 메시지 정의 (.proto)
- [ ] Swift 코드 생성
- [ ] PacketHeader/Encoder/Decoder 구현
- [ ] NetworkConstants 정의

---

### 1.2 iOS 앱 기본 구조

> TCA 기반 앱 구조 설정

**완료 조건:**
- [ ] AppFeature (Root Reducer)
- [ ] TabFeature (탭 관리)
- [ ] 모드별 탭 구성

---

### 1.3 macOS 서버 구현

> TCP/UDP 서버 및 메뉴바 앱

**완료 조건:**
- [ ] NWListener 기반 TCP/UDP 서버
- [ ] 메뉴바 아이콘 (LSUIElement)
- [ ] 연결 상태 표시

---

### 1.4 디바이스 연결

> Bonjour 검색 및 연결 관리

**완료 조건:**
- [ ] Bonjour 서비스 광고/검색
- [ ] Handshake 프로토콜
- [ ] ConnectionManager

---

### 2.1 트랙패드

> 마우스 이동, 클릭, 스크롤

**완료 조건:**
- [ ] 1손가락 이동 (마우스)
- [ ] 탭/더블탭 (클릭)
- [ ] 2손가락 스크롤
- [ ] 감도 조절

---

### 2.2 키보드

> 텍스트 입력 및 특수키

**완료 조건:**
- [ ] iOS 키보드 연동
- [ ] 한/영 전환
- [ ] 특수키 (Return, Delete, 방향키)
- [ ] 조합키 (Cmd+C 등)

---

### 2.3 미디어 컨트롤

> 재생/정지, 볼륨 제어

**완료 조건:**
- [ ] 재생/일시정지
- [ ] 이전/다음 곡
- [ ] 볼륨 조절

---

### 2.4 macOS 접근성

> 접근성 권한 및 CGEvent

**완료 조건:**
- [ ] AXIsProcessTrusted 확인
- [ ] 권한 요청 UI
- [ ] CGEvent 기반 입력 컨트롤러

---

### 3.1 윈도우 스냅

> AXUIElement 기반 윈도우 관리

**완료 조건:**
- [ ] 10가지 스냅 포지션
- [ ] 멀티 디스플레이 지원

---

### 3.2 앱 스위처

> 실행 앱 목록 및 전환

**완료 조건:**
- [ ] NSWorkspace 앱 목록
- [ ] 앱 아이콘 추출
- [ ] 포커스 전환

---

### 3.3 매크로 패드

> Bento Grid UI 및 커스텀 매크로

**완료 조건:**
- [ ] 기본 매크로 (복사, 붙여넣기 등)
- [ ] 커스텀 매크로 편집
- [ ] Bento Grid 레이아웃

---

### 4.1 레이저 포인터

> CoreMotion 자이로 기반 Air Mouse

**완료 조건:**
- [ ] 자이로스코프 데이터 수집
- [ ] 모션 → 커서 변환
- [ ] 캘리브레이션

---

### 4.2 프레젠테이션 헬퍼

> 슬라이드 제어 및 발표 타이머

**완료 조건:**
- [ ] 이전/다음 슬라이드
- [ ] 발표 타이머
- [ ] 햅틱 피드백

---

### 4.3 음성 타이핑

> SFSpeechRecognizer 음성 인식

**완료 조건:**
- [ ] 마이크 권한 요청
- [ ] 실시간 음성 인식
- [ ] 텍스트 전송

---

### 4.4 UI/UX 디자인

> 디자인 시스템 적용

**완료 조건:**
- [ ] Deep Dark Mode
- [ ] Bento Grid 레이아웃
- [ ] Neon Accent Colors
- [ ] 햅틱 피드백

---

### 4.5 플랫폼 확장

> 다양한 플랫폼 지원

**포함 기능:**
- Apple TV (tvOS) 리모컨
- iPad (iPadOS) Receiver
- Vision Pro (visionOS)
- Windows Receiver
- Linux / Raspberry Pi
- Samsung Smart TV (Tizen)
- LG Smart TV (webOS)

**Post-MVP:**
- TLS/DTLS 암호화
- 페어링 코드 인증
- 멀티 디바이스
- 클라우드 동기화
- iOS 위젯
- Siri Shortcuts

---

## 마일스톤 워크플로우

### 이슈 생성 시

```bash
# 마이크로 마일스톤 지정
gh issue create --title "[Feat]: 새 기능" --milestone "2.1 트랙패드"
```

### 진행률 확인

```bash
gh api repos/unib35/Snap/milestones --jq '.[] | "\(.title): \(.closed_issues)/\(.open_issues + .closed_issues)"'
```

### 마일스톤 완료

```bash
gh api repos/unib35/Snap/milestones/{number} -X PATCH -f state="closed"
```

---

## 라벨과의 관계

| Phase | 마이크로 마일스톤 | 라벨 |
| --- | --- | --- |
| Phase 1 | 1.1 ~ 1.4 | `phase: foundation` |
| Phase 2 | 2.1 ~ 2.4 | `phase: essentials` |
| Phase 3 | 3.1 ~ 3.3 | `phase: productivity` |
| Phase 4 | 4.1 ~ 4.5 | `phase: polish` |

---

## 관련 문서

- [이슈 라벨 가이드](./issue-labels.md)
- [이슈 템플릿](./issue-template.md)
- [릴리즈 워크플로우](./release-workflow.md)
- [PRD](../design/PRD.md)
