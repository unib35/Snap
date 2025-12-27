# 버전 관리 가이드 (Changesets)

이 문서는 Acadesk v2 모노레포의 패키지 버전 관리 방법을 설명합니다.

## 개요

[Changesets](https://github.com/changesets/changesets)를 사용하여 패키지 버전을 관리합니다.

### 왜 Changesets인가?

- **자동화된 버전 관리**: PR마다 변경사항을 기록하고, 릴리즈 시 자동으로 버전 범프
- **CHANGELOG 자동 생성**: 변경사항이 자동으로 CHANGELOG.md에 기록됨
- **모노레포 최적화**: 패키지간 의존성을 자동으로 추적하고 업데이트
- **협업 친화적**: 여러 기여자의 변경사항을 하나의 릴리즈로 통합

## 버전 관리 대상

| 패키지               | 버전 관리 | 비고                            |
| -------------------- | --------- | ------------------------------- |
| `@acadesk/ui`        | ✅        | UI 컴포넌트 라이브러리          |
| `@acadesk/database`  | ✅        | 데이터베이스 타입 및 클라이언트 |
| `@acadesk/utils`     | ✅ (예정) | 유틸리티 함수                   |
| `@acadesk/error`     | ✅ (예정) | 에러 핸들링                     |
| `@acadesk/messaging` | ✅ (예정) | 메시징 (SMS, 알림톡)            |
| `web` (apps/web)     | ❌        | 앱은 버전 관리 제외             |

## Semantic Versioning

[SemVer](https://semver.org/lang/ko/) 규칙을 따릅니다: `MAJOR.MINOR.PATCH`

### 버전 범프 기준

| 타입    | 언제 사용?                          | 예시                  | 버전 변화     |
| ------- | ----------------------------------- | --------------------- | ------------- |
| `patch` | 버그 수정, 문서 수정, 내부 리팩토링 | 버튼 스타일 버그 수정 | 0.1.0 → 0.1.1 |
| `minor` | 새로운 기능 추가 (하위 호환)        | 새 컴포넌트 추가      | 0.1.0 → 0.2.0 |
| `major` | Breaking changes                    | API 시그니처 변경     | 0.1.0 → 1.0.0 |

### Breaking Change 예시

- 컴포넌트 props 이름/타입 변경
- 함수 시그니처 변경
- 필수 props 추가
- 기존 export 삭제

## 사용 방법

### 1. 변경사항 기록 (PR 생성 전)

패키지를 변경한 후, PR 생성 전에 changeset을 추가합니다:

```bash
pnpm changeset
```

대화형 프롬프트가 실행됩니다:

```
🦋  Which packages would you like to include?
   ◯ @acadesk/ui
   ◯ @acadesk/database

🦋  Which packages should have a major bump?
   (선택 안함 → minor 또는 patch 선택)

🦋  Which packages should have a minor bump?
   ◯ @acadesk/ui

🦋  Please enter a summary for this change:
   Button 컴포넌트에 loading 상태 추가
```

`.changeset/` 폴더에 랜덤 이름의 `.md` 파일이 생성됩니다:

```markdown
---
"@acadesk/ui": minor
---

Button 컴포넌트에 loading 상태 추가
```

### 2. Changeset 파일 커밋

생성된 changeset 파일을 커밋에 포함합니다:

```bash
git add .changeset/
git commit -m "[Feat]: Button loading 상태 추가"
```

### 3. PR 생성 및 머지

일반적인 PR 워크플로우를 따릅니다. PR 템플릿의 Changeset 체크리스트를 확인하세요.

### 4. 버전 업데이트 (릴리즈 시)

머지된 changeset들을 기반으로 버전을 업데이트합니다:

```bash
pnpm version
```

이 명령은:

- 각 패키지의 `package.json` 버전 업데이트
- `CHANGELOG.md` 생성/업데이트
- `.changeset/` 폴더의 changeset 파일 삭제

### 5. 패키지 배포 (선택)

npm에 배포가 필요한 경우:

```bash
pnpm release
```

> 현재는 private 패키지로 npm 배포 없이 내부 사용만 합니다.

## 자주 묻는 질문

### Q: 언제 changeset을 추가해야 하나요?

**추가해야 하는 경우:**

- `packages/*` 폴더의 파일을 변경했을 때
- 새 컴포넌트, 함수, 타입을 추가했을 때
- 기존 API를 변경했을 때

**추가하지 않아도 되는 경우:**

- `apps/web`만 변경한 경우
- 테스트 파일만 변경한 경우
- 문서만 변경한 경우 (선택사항)
- `.github/`, `docs/` 등 설정 파일만 변경한 경우

### Q: 여러 패키지를 동시에 변경했으면?

하나의 changeset에 여러 패키지를 포함할 수 있습니다:

```markdown
---
"@acadesk/ui": minor
"@acadesk/database": patch
---

Form 컴포넌트 추가 및 관련 타입 수정
```

### Q: changeset 없이 PR을 머지하면?

패키지 변경이 있었지만 changeset이 없으면 해당 변경은 버전에 반영되지 않습니다. CI에서 경고가 발생할 수 있습니다 (추후 구축 예정).

### Q: 잘못된 changeset을 생성했으면?

`.changeset/` 폴더에서 해당 `.md` 파일을 직접 수정하거나 삭제하면 됩니다.

### Q: linked 설정이 뭔가요?

`.changeset/config.json`의 `linked` 설정은 패키지들을 그룹으로 묶습니다. 그룹 내 한 패키지가 major bump되면 다른 패키지들도 같이 major bump됩니다.

현재 설정:

```json
{
  "linked": [["@acadesk/ui", "@acadesk/database"]]
}
```

## 설정 파일

### `.changeset/config.json`

```json
{
  "$schema": "https://unpkg.com/@changesets/config@3.1.2/schema.json",
  "changelog": "@changesets/cli/changelog",
  "commit": false,
  "fixed": [],
  "linked": [["@acadesk/ui", "@acadesk/database"]],
  "access": "restricted",
  "baseBranch": "main",
  "updateInternalDependencies": "patch",
  "ignore": ["web"],
  "privatePackages": {
    "version": true,
    "tag": true
  }
}
```

| 설정         | 설명                                      |
| ------------ | ----------------------------------------- |
| `linked`     | 함께 버전이 올라가는 패키지 그룹          |
| `ignore`     | 버전 관리에서 제외할 패키지               |
| `baseBranch` | 기본 브랜치 (main)                        |
| `access`     | npm 배포 접근 권한 (restricted = private) |

## 명령어 요약

| 명령어                  | 설명                            |
| ----------------------- | ------------------------------- |
| `pnpm changeset`        | 새 changeset 생성 (대화형)      |
| `pnpm changeset add`    | 새 changeset 생성 (대화형)      |
| `pnpm changeset status` | 현재 changeset 상태 확인        |
| `pnpm version`          | 버전 업데이트 및 CHANGELOG 생성 |
| `pnpm release`          | npm 배포 (현재 미사용)          |

## 참고 자료

- [Changesets 공식 문서](https://github.com/changesets/changesets)
- [Semantic Versioning](https://semver.org/lang/ko/)
- [Changesets GitHub Actions](https://github.com/changesets/action)
