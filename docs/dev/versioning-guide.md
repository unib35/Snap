# 버전 관리 가이드

이 문서는 Snap 프로젝트의 앱 버전 관리 방법을 설명합니다.

## 개요

Snap은 iOS 앱과 macOS 앱으로 구성됩니다. 두 앱의 버전은 동기화하여 관리합니다.

## Semantic Versioning

[SemVer](https://semver.org/lang/ko/) 규칙을 따릅니다: `MAJOR.MINOR.PATCH`

### 버전 범프 기준

| 타입 | 언제 사용? | 예시 | 버전 변화 |
| --- | --- | --- | --- |
| `PATCH` | 버그 수정, 성능 개선 | 연결 안정성 개선 | 1.0.0 → 1.0.1 |
| `MINOR` | 새로운 기능 추가 | 레이저 포인터 추가 | 1.0.0 → 1.1.0 |
| `MAJOR` | Breaking changes, 대규모 변경 | 프로토콜 전면 개편 | 1.0.0 → 2.0.0 |

## 버전 정보 위치

### Project.swift

```swift
// iOS App
.target(
    name: "App",
    ...
    infoPlist: .extendingDefault(with: [
        "CFBundleShortVersionString": "1.0.0",  // 버전
        "CFBundleVersion": "1",                  // 빌드 번호
        ...
    ]),
    ...
)

// macOS App
.target(
    name: "MacReceiver",
    ...
    infoPlist: .extendingDefault(with: [
        "CFBundleShortVersionString": "1.0.0",  // 버전
        "CFBundleVersion": "1",                  // 빌드 번호
        ...
    ]),
    ...
)
```

### 버전 vs 빌드 번호

| 항목 | 키 | 용도 | 예시 |
| --- | --- | --- | --- |
| **버전** | CFBundleShortVersionString | 사용자에게 표시 | "1.2.0" |
| **빌드 번호** | CFBundleVersion | 내부 추적용 | "42" |

## 릴리즈 워크플로우

### 1. 버전 업데이트

Project.swift에서 두 앱의 버전을 동시에 업데이트합니다:

```swift
// 버전 상수로 관리 (권장)
let appVersion = "1.1.0"
let buildNumber = "1"
```

### 2. 커밋

```bash
git commit -m "[Chore]: v1.1.0 릴리즈 준비"
```

### 3. 태그 생성

```bash
git tag -a v1.1.0 -m "Release v1.1.0"
git push origin v1.1.0
```

### 4. GitHub 릴리즈

```bash
gh release create v1.1.0 \
  --title "v1.1.0" \
  --notes "## What's Changed
- 새 기능 A
- 버그 수정 B

**Full Changelog**: https://github.com/unib35/Snap/compare/v1.0.0...v1.1.0"
```

## 빌드 번호 관리

### 자동 증가 (권장)

CI/CD에서 빌드 시 자동으로 증가시킵니다:

```bash
# 현재 빌드 번호 가져오기
BUILD_NUMBER=$(git rev-list --count HEAD)

# 또는 날짜 기반
BUILD_NUMBER=$(date +%Y%m%d%H%M)
```

### 수동 관리

릴리즈 시에만 수동으로 업데이트합니다:
- 같은 버전 내에서 빌드마다 증가
- 버전 업데이트 시 1로 리셋

## Pre-release 버전

### 베타 버전

```
1.1.0-beta.1
1.1.0-beta.2
```

### RC (Release Candidate)

```
1.1.0-rc.1
1.1.0-rc.2
```

## TestFlight 배포

### 버전 규칙

- 같은 버전에 여러 빌드 업로드 가능
- 빌드 번호는 반드시 증가해야 함
- 버전 + 빌드 조합은 유니크해야 함

### 예시

| 버전 | 빌드 | 상태 |
| --- | --- | --- |
| 1.0.0 | 1 | 첫 번째 빌드 |
| 1.0.0 | 2 | 버그 수정 후 재빌드 |
| 1.0.1 | 1 | 패치 릴리즈 |
| 1.1.0 | 1 | 새 기능 릴리즈 |

## 프로토콜 버전

### ProtocolSpec.md

패킷 헤더에 프로토콜 버전이 포함됩니다:

```
| Version | 1 byte | 프로토콜 버전 (현재 0x01) |
```

### 호환성 관리

| 앱 버전 | 프로토콜 버전 | 호환성 |
| --- | --- | --- |
| 1.0.x | 0x01 | 상호 호환 |
| 1.1.x | 0x01 | 상호 호환 |
| 2.0.x | 0x02 | 1.x와 비호환 |

## 관련 문서

- [릴리즈 워크플로우](../git/release-workflow.md)
- [프로토콜 명세](../design/ProtocolSpec.md)
