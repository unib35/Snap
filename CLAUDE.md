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
- Swift 6.2

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
