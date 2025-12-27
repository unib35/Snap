# GitHub 이슈 라벨 가이드

이 문서는 Snap 프로젝트에서 사용하는 GitHub 이슈 라벨을 정의합니다.

> **총 50개 라벨** (2025년 12월 기준)

---

## 라벨 카테고리

### 1. 타입 (Type) - 10개

이슈의 종류를 나타냅니다. **필수**로 하나 이상 선택합니다.

| 라벨          | 색상       | 설명                           |
| ------------- | ---------- | ------------------------------ |
| `feat`        | 🔵 #1D76DB | 새로운 기능 구현               |
| `bug`         | 🔴 #d73a4a | 버그, 오류 수정                |
| `design`      | 🩷 #ff99cc | UI 구현 및 뷰 관련             |
| `refactor`    | 🔵 #A2EEEF | 코드 리팩토링                  |
| `setting`     | 🔵 #0052CC | 프로젝트 세팅                  |
| `performance` | 🟠 #ff9800 | 성능 최적화                    |
| `chore`       | ⚪ #ededed | 빌드, 설정, 잡무               |
| `test`        | 🟢 #0e8a16 | 테스트 작성 또는 수정          |
| `docs`        | 🔵 #0075ca | 문서 작성 또는 수정            |
| `hotfix`      | 🔴 #ff0000 | 프로덕션 긴급 수정             |

### 2. 우선순위 (Priority) - 7개

작업의 긴급도를 나타냅니다.

| 라벨                 | 색상       | 설명                     |
| -------------------- | ---------- | ------------------------ |
| `P0`                 | 🔴 #B60205 | 최우선순위               |
| `P1`                 | 🟡 #FBCA04 | 높은 우선순위            |
| `P2`                 | 🔵 #C5DEF5 | 일반 우선순위            |
| `priority: critical` | 🔴 #b60205 | 즉시 수정 필요 (24시간)  |
| `priority: high`     | 🟠 #d93f0b | 높은 우선순위 (1주일)    |
| `priority: medium`   | 🟡 #fbca04 | 중간 우선순위 (2주일)    |
| `priority: low`      | 🟢 #c2e0c6 | 낮은 우선순위 (백로그)   |

### 3. 상태 (Status) - 5개

이슈의 진행 상태를 나타냅니다.

| 라벨                      | 색상       | 설명             |
| ------------------------- | ---------- | ---------------- |
| `status: in progress`     | 🔵 #1d76db | 작업 진행 중     |
| `status: review needed`   | 🟠 #f9d0c4 | 코드 리뷰 필요   |
| `status: blocked`         | 🔴 #e11d21 | 블로킹됨         |
| `status: on hold`         | ⚪ #bfd4f2 | 일시 보류        |
| `status: ready for merge` | 🟢 #0e8a16 | 머지 대기        |

### 4. 모듈 (Module) - 3개

영향받는 프로젝트 모듈을 나타냅니다.

| 라벨              | 색상       | 경로                   | 설명             |
| ----------------- | ---------- | ---------------------- | ---------------- |
| `module: app`     | 🔵 #006b75 | `Projects/App`         | iOS 앱           |
| `module: receiver`| 🟣 #5319e7 | `Projects/MacReceiver` | macOS Receiver   |
| `module: shared`  | 🔵 #84b6eb | `Projects/Shared`      | 공유 코드        |

### 5. 플랫폼 (Platform) - 2개

| 라벨              | 색상       | 설명        |
| ----------------- | ---------- | ----------- |
| `platform: iOS`   | 🔵 #147efb | iOS 관련    |
| `platform: macOS` | ⚫ #1d1d1f | macOS 관련  |

### 6. 기능 영역 (Area) - 10개

PRD의 기능별 영역을 나타냅니다.

| 라벨                 | 색상       | 설명                    |
| -------------------- | ---------- | ----------------------- |
| `area: trackpad`     | 🔵 #bfdadc | 트랙패드/마우스 제어    |
| `area: keyboard`     | 🔵 #c5def5 | 키보드 입력             |
| `area: media`        | 🟡 #fef2c0 | 미디어 컨트롤           |
| `area: window`       | 🟠 #f7c6c7 | 윈도우 스냅             |
| `area: app-switcher` | 🟢 #c2f0c2 | 앱 스위처               |
| `area: macro`        | 🟤 #e6ccb3 | 매크로 패드             |
| `area: presenter`    | 🟢 #d4edda | 발표 모드 (레이저 포인터) |
| `area: voice`        | ⚪ #e2e3e5 | 음성 입력               |
| `area: connection`   | 🟣 #d4c5f9 | 연결/디스커버리         |
| `area: settings`     | ⚪ #e2e3e5 | 설정                    |

### 7. 개발 단계 (Phase) - 4개

PRD 로드맵의 개발 단계를 나타냅니다.

| 라벨                  | 색상       | 설명                    |
| --------------------- | ---------- | ----------------------- |
| `phase: foundation`   | 🔵 #3f51b5 | Phase 1: 기반 구축      |
| `phase: essentials`   | 🔵 #2196f3 | Phase 2: 기본 기능      |
| `phase: productivity` | 🟢 #4caf50 | Phase 3: 생산성 기능    |
| `phase: polish`       | 🟣 #9c27b0 | Phase 4: 완성도         |

### 8. 기술 스택 (Tech) - 7개

사용되는 기술 스택을 나타냅니다.

| 라벨                     | 색상       | 설명                        |
| ------------------------ | ---------- | --------------------------- |
| `tech: tca`              | 🟣 #5319e7 | The Composable Architecture |
| `tech: swiftui`          | 🔴 #f05138 | SwiftUI 관련                |
| `tech: protobuf`         | 🟢 #34a853 | Protocol Buffers            |
| `tech: network`          | 🔵 #0052cc | 네트워크/소켓 통신          |
| `tech: accessibility-api`| 🟠 #ff5722 | macOS Accessibility API     |
| `tech: cgevent`          | 🟤 #795548 | CGEvent (키/마우스)         |
| `tech: coremotion`       | 🔵 #00bcd4 | CoreMotion (자이로스코프)   |

### 9. 품질 (Quality) - 3개

| 라벨              | 색상       | 설명            |
| ----------------- | ---------- | --------------- |
| `security`        | 🔴 #ee0701 | 보안 관련       |
| `tech debt`       | ⚪ #607d8b | 기술 부채       |
| `breaking change` | 🔴 #d73a4a | Breaking Change |

### 10. 기타 (Miscellaneous) - 6개

| 라벨               | 색상       | 설명                 |
| ------------------ | ---------- | -------------------- |
| `good first issue` | 🟣 #7057ff | 신규 기여자에게 적합 |
| `help wanted`      | 🟢 #008672 | 추가 도움 필요       |
| `question`         | 🟣 #d876e3 | 추가 정보 요청       |
| `duplicate`        | ⚪ #cfd3d7 | 중복 이슈            |
| `invalid`          | 🟡 #e4e669 | 유효하지 않은 이슈   |
| `wontfix`          | ⚪ #ffffff | 수정하지 않을 이슈   |

---

## 라벨 사용 가이드

### 이슈 생성 시

1. **타입 라벨 필수**: 최소 1개의 타입 라벨 선택
2. **우선순위 라벨**: P0/P1/P2 중 선택
3. **Phase 라벨 권장**: 개발 단계 명시
4. **영역 라벨 권장**: 관련 기능 영역 선택
5. **모듈 라벨 권장**: 영향받는 모듈 선택

```
예시: 트랙패드 UDP 구현 이슈
라벨: feat, P0, phase: essentials, area: trackpad, module: app, module: receiver, tech: network
```

### 작업 진행 시

1. 작업 시작 → `status: in progress` 추가
2. PR 생성 → `status: review needed` 추가
3. 블로킹 발생 → `status: blocked` 추가 (코멘트로 사유 명시)
4. 승인 완료 → `status: ready for merge` 추가

### 라벨 조합 예시

| 상황                    | 라벨 조합                                                          |
| ----------------------- | ------------------------------------------------------------------ |
| 트랙패드 기능 개발      | `feat` + `P0` + `phase: essentials` + `area: trackpad`             |
| 키보드 버그 수정        | `bug` + `P1` + `area: keyboard` + `module: receiver`               |
| Protobuf 정의           | `setting` + `P0` + `phase: foundation` + `tech: protobuf`          |
| 레이저 포인터 구현      | `feat` + `P2` + `phase: polish` + `area: presenter` + `tech: coremotion` |
| macOS 접근성 권한       | `setting` + `P0` + `platform: macOS` + `tech: accessibility-api`   |
| UI 디자인 적용          | `design` + `P2` + `phase: polish` + `module: app`                  |
| 네트워크 성능 최적화    | `performance` + `area: connection` + `tech: network`               |

---

## 라벨 관리

### 새 라벨 추가

```bash
gh label create "area: new-feature" --description "새 기능 영역" --color "c5def5"
```

### 라벨 수정

```bash
gh label edit "bug" --description "새로운 설명" --color "ff0000"
```

### 라벨 삭제

```bash
gh label delete "라벨명" --yes
```

### 전체 라벨 조회

```bash
gh label list --limit 100
```

---

## 관련 문서

- [이슈 템플릿](./issue-template.md)
- [브랜치 컨벤션](./branch.md)
- [커밋 컨벤션](./commit.md)
- [마이크로 브랜치 전략](./micro-strategy.md)
