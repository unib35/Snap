# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Snap is a dual-platform remote control system: an iOS app (sender) that controls a macOS app (receiver). The iOS app sends trackpad gestures, keyboard input, and sensor data to the Mac for low-latency remote control.

## Build Commands

```bash
# Generate Xcode project with Tuist
tuist generate

# Build iOS app
tuist build App

# Build macOS receiver
tuist build MacReceiver

# Run tests
tuist test
```

## Architecture

### Project Structure
- **Projects/App** - iOS sender app (SwiftUI + TCA)
- **Projects/MacReceiver** - macOS receiver app
- **Projects/Shared** - Shared code and Protobuf definitions

### Network Protocol
- **UDP** - Mouse/trackpad coordinates, gyroscope data (low latency, loss tolerant)
- **TCP** - Keyboard input, system commands, media control (reliable delivery)
- **Bonjour** - Zero-config device discovery
- **Protobuf** - Binary packet serialization (`.proto` files in `Projects/Shared/Resources/Proto/`)

### iOS App Pattern
Uses The Composable Architecture (TCA) with SwiftUI.

### macOS Receiver
Uses Accessibility API (`AXUIElement`) and `CGEvent` for system control. Requires accessibility permissions.

## Platform Requirements
- iOS 17.0+
- macOS 14.0+
- Swift 6.0

## Code Quality Tools

### SwiftLint
프로젝트에 SwiftLint가 통합되어 있습니다. 빌드 시 자동으로 실행됩니다.

```bash
# 수동 실행
swiftlint lint --config .swiftlint.yml

# 자동 수정 (가능한 경우)
swiftlint --fix --config .swiftlint.yml
```

설정 파일: `.swiftlint.yml`

### SourceKit-LSP
VS Code에서 Swift 개발 시 SourceKit-LSP를 사용합니다.

**필수 확장 프로그램:**
- Swift (sswg.swift-lang)

**설정 확인:**
- `.vscode/settings.json` - SourceKit-LSP 설정
- `.vscode/extensions.json` - 추천 확장 프로그램

**사용 전 필수:**
```bash
tuist generate  # Xcode 프로젝트 생성 필요
```

## Git Workflow

### Branch Convention
```
{type}/{description}  (kebab-case)
```
- `feat/login-with-social-account`
- `fix/image-caching-error`
- `refactor/separate-viewmodel-logic`

### Commit Convention
```
[Type]: 제목 (50자 이내, 명령문, 마침표 없음)

- 세부 내용

Close #이슈번호
```

Types: `[Feat]`, `[Fix]`, `[Refactor]`, `[Design]`, `[Setting]`, `[Chore]`, `[Docs]`, `[Test]`, `[Perf]`, `[Add]`, `[Del]`, `[Remove]`

### Workflow
1. develop 브랜치에서 feature 브랜치 생성
2. 마이크로 커밋으로 작업 (하나의 논리적 변경 = 하나의 커밋)
3. PR 생성 후 스쿼시 머지
4. develop → main 릴리즈 시 태그 생성

### Issue Management
- 모든 작업은 GitHub Issue로 등록
- 커밋 시 `Close #이슈번호`로 연결
- 템플릿: `docs/git/issue-template.md`
- 라벨 가이드: `docs/git/issue-labels.md`

### Milestones
| Phase | 설명 | 주요 기능 |
|-------|------|-----------|
| Phase 1: Foundation | 기반 구축 | 소켓 연결, Protobuf, Bonjour |
| Phase 2: Essentials | 기본 기능 | 트랙패드, 키보드, 미디어 |
| Phase 3: Productivity | 생산성 기능 | 윈도우 스냅, 앱 스위처, 매크로 |
| Phase 4: Polish | 완성도 | 레이저 포인터, 보이스, UI |

상세: `docs/git/milestones.md`
