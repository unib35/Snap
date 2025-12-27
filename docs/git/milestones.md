# GitHub 마일스톤 가이드

이 문서는 Snap 프로젝트에서 사용하는 GitHub 마일스톤을 정의합니다.

---

## 마일스톤 개요

마일스톤은 PRD 로드맵의 개발 단계(Phase)와 1:1로 매핑됩니다. 각 마일스톤은 특정 기능 세트의 완료를 목표로 합니다.

| 마일스톤 | 설명 | 우선순위 | 주요 기능 |
| --- | --- | --- | --- |
| **Phase 1: Foundation** | 기반 구축 | P0 | 소켓 연결, Protobuf, Bonjour |
| **Phase 2: Essentials** | 기본 기능 | P0 | 트랙패드, 키보드, 미디어, 접근성 |
| **Phase 3: Productivity** | 생산성 기능 | P1 | 윈도우 스냅, 앱 스위처, 매크로 |
| **Phase 4: Polish & Expansion** | 완성도 | P2 | 레이저 포인터, 보이스 타이핑, UI |

---

## 마일스톤 상세

### Phase 1: Foundation (기반 구축)

> iOS ↔ macOS 통신 기반을 구축합니다.

**목표:**
- 두 플랫폼 간 안정적인 소켓 연결 확립
- Protobuf 기반 데이터 직렬화 체계 구축
- Bonjour를 통한 자동 디바이스 검색

**포함 이슈:**
- #1 iOS ↔ macOS 소켓 연결 (Echo Test)
- #2 Protobuf 데이터 구조 정의 및 컴파일
- #14 Bonjour 디바이스 자동 검색

**완료 조건:**
- [ ] TCP/UDP 소켓으로 양방향 통신 가능
- [ ] Protobuf 메시지 송수신 검증
- [ ] 같은 네트워크 내 자동 디바이스 발견

---

### Phase 2: Essentials (기본 기능)

> 핵심 원격 제어 기능을 구현합니다.

**목표:**
- 유선 마우스 수준의 저지연 트랙패드
- iOS 키보드를 통한 Mac 텍스트 입력
- 미디어 재생 및 볼륨 제어
- macOS 접근성 권한 획득 로직

**포함 이슈:**
- #3 트랙패드 (UDP) 구현 및 감도 조절
- #4 키보드 입력 (TCP) 구현
- #5 macOS 접근성 권한 획득 로직
- #7 미디어 컨트롤 & 볼륨 동기화

**완료 조건:**
- [ ] 1손가락 이동, 2손가락 스크롤 동작
- [ ] 한/영, 특수키 포함 텍스트 입력 가능
- [ ] 재생/정지, 볼륨 조절 동작
- [ ] 접근성 권한 요청 및 상태 표시

---

### Phase 3: Productivity (생산성 기능)

> Mac 파워 유저를 위한 생산성 도구를 구현합니다.

**목표:**
- Rectangle 스타일 윈도우 스냅
- 실행 중인 앱 목록 표시 및 전환
- 커스터마이징 가능한 매크로 패드

**포함 이슈:**
- #6 윈도우 스냅 (Accessibility API)
- #8 앱 스위처 (양방향 통신)
- #9 매크로 패드 (Bento Grid UI)

**완료 조건:**
- [ ] 10가지 윈도우 스냅 포지션 동작
- [ ] Mac 앱 목록 조회 및 포커스 전환
- [ ] 기본 매크로 제공 및 사용자 정의 가능

---

### Phase 4: Polish & Expansion (완성도)

> 킬러 기능과 UI 완성도를 높입니다.

**목표:**
- 아이폰 자이로를 활용한 레이저 포인터
- 음성 인식 텍스트 입력
- 발표 전용 컨트롤러
- PRD 디자인 가이드라인 적용

**포함 이슈:**
- #10 자이로스코프 레이저 포인터 (Air Mouse)
- #11 보이스 타이핑 (음성 → 텍스트)
- #12 프레젠테이션 헬퍼 (슬라이드 제어)
- #13 UI 디자인 적용 (Bento Grid, Deep Dark Mode)

**완료 조건:**
- [ ] 아이폰 기울기로 커서 이동
- [ ] 음성 인식 후 Mac에 텍스트 입력
- [ ] 슬라이드 넘김 및 발표 타이머 동작
- [ ] Bento Grid UI, 햅틱 피드백, 다크 모드 적용

---

## 마일스톤 워크플로우

### 1. 이슈 생성 시

새 이슈를 생성할 때 해당하는 마일스톤을 지정합니다.

```bash
gh issue create --title "[Feat]: 새 기능" --milestone "Phase 2: Essentials"
```

### 2. 마일스톤 진행률 확인

```bash
# 마일스톤 목록 및 진행률
gh api repos/{owner}/{repo}/milestones --jq '.[] | "\(.title): \(.closed_issues)/\(.open_issues + .closed_issues) (\(.closed_issues * 100 / (.open_issues + .closed_issues) | floor)%)"'
```

### 3. 마일스톤 완료

모든 이슈가 닫히면 마일스톤을 종료합니다.

```bash
gh api repos/{owner}/{repo}/milestones/{number} -X PATCH -f state="closed"
```

---

## 마일스톤 관리 명령어

### 마일스톤 생성

```bash
gh api repos/{owner}/{repo}/milestones \
  -f title="Phase 5: New Feature" \
  -f description="새로운 기능 설명" \
  -f due_on="2025-03-31T23:59:59Z" \
  -f state="open"
```

### 마일스톤 수정

```bash
gh api repos/{owner}/{repo}/milestones/{number} -X PATCH \
  -f description="수정된 설명" \
  -f due_on="2025-04-30T23:59:59Z"
```

### 마일스톤 조회

```bash
# 전체 목록
gh api repos/{owner}/{repo}/milestones

# 특정 마일스톤의 이슈 목록
gh issue list --milestone "Phase 1: Foundation"
```

### 마일스톤 삭제

```bash
gh api repos/{owner}/{repo}/milestones/{number} -X DELETE
```

---

## 라벨과의 관계

마일스톤과 `phase:` 라벨은 동일한 개발 단계를 나타냅니다.

| 마일스톤 | 라벨 |
| --- | --- |
| Phase 1: Foundation | `phase: foundation` |
| Phase 2: Essentials | `phase: essentials` |
| Phase 3: Productivity | `phase: productivity` |
| Phase 4: Polish & Expansion | `phase: polish` |

**권장 사항:**
- 이슈에는 마일스톤과 해당 phase 라벨 모두 지정
- 마일스톤은 진행률 추적, 라벨은 필터링에 활용

---

## 관련 문서

- [이슈 라벨 가이드](./issue-labels.md)
- [이슈 템플릿](./issue-template.md)
- [릴리즈 워크플로우](./release-workflow.md)
- [PRD](../design/PRD.md)
