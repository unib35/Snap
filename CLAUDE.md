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
