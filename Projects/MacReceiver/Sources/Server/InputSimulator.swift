import Foundation
import CoreGraphics
import Shared

/// 입력 시뮬레이터 (마우스, 키보드 이벤트 주입)
public final class InputSimulator: @unchecked Sendable {
    // MARK: - Singleton

    public static let shared = InputSimulator()

    private init() {}

    // MARK: - Mouse

    /// 마우스 이동 (상대 좌표)
    public func moveMouse(deltaX: CGFloat, deltaY: CGFloat) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: .mouseMoved,
            mouseCursorPosition: currentMouseLocation(),
            mouseButton: .left
        ) else { return }

        // 상대 좌표로 이동
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY))
        event.post(tap: .cghidEventTap)
    }

    /// 마우스 클릭
    public func mouseClick(button: MouseClick.Button, action: MouseClick.Action) {
        let location = currentMouseLocation()

        switch action {
        case .down:
            postMouseEvent(type: buttonDownType(for: button), button: cgButton(for: button), at: location)
        case .up:
            postMouseEvent(type: buttonUpType(for: button), button: cgButton(for: button), at: location)
        case .click:
            postMouseEvent(type: buttonDownType(for: button), button: cgButton(for: button), at: location)
            postMouseEvent(type: buttonUpType(for: button), button: cgButton(for: button), at: location)
        case .double:
            postMouseEvent(type: buttonDownType(for: button), button: cgButton(for: button), at: location, clickCount: 1)
            postMouseEvent(type: buttonUpType(for: button), button: cgButton(for: button), at: location, clickCount: 1)
            postMouseEvent(type: buttonDownType(for: button), button: cgButton(for: button), at: location, clickCount: 2)
            postMouseEvent(type: buttonUpType(for: button), button: cgButton(for: button), at: location, clickCount: 2)
        }
    }

    /// 스크롤
    public func scroll(deltaX: CGFloat, deltaY: CGFloat) {
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: Int32(deltaY),
            wheel2: Int32(deltaX),
            wheel3: 0
        ) else { return }

        event.post(tap: .cghidEventTap)
    }

    // MARK: - Keyboard

    /// 키 이벤트
    public func keyEvent(keyCode: UInt32, action: KeyEvent.Action, modifiers: UInt32) {
        switch action {
        case .down:
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: true, modifiers: modifiers)
        case .up:
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: false, modifiers: modifiers)
        case .press:
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: true, modifiers: modifiers)
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: false, modifiers: modifiers)
        }
    }

    /// 키 조합 실행
    public func executeKeyCombo(keyCodes: [UInt32], modifiers: UInt32) {
        // 모디파이어 키 다운
        setModifiers(modifiers, keyDown: true)

        // 키 프레스
        for keyCode in keyCodes {
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: true, modifiers: modifiers)
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: false, modifiers: modifiers)
        }

        // 모디파이어 키 업
        setModifiers(modifiers, keyDown: false)
    }

    // MARK: - Private Helpers

    private func currentMouseLocation() -> CGPoint {
        CGEvent(source: nil)?.location ?? .zero
    }

    private func postMouseEvent(
        type: CGEventType,
        button: CGMouseButton,
        at location: CGPoint,
        clickCount: Int = 1
    ) {
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: location,
            mouseButton: button
        ) else { return }

        event.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
        event.post(tap: .cghidEventTap)
    }

    private func postKeyEvent(keyCode: CGKeyCode, keyDown: Bool, modifiers: UInt32) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else {
            return
        }

        event.flags = cgEventFlags(from: modifiers)
        event.post(tap: .cghidEventTap)
    }

    private func setModifiers(_ modifiers: UInt32, keyDown: Bool) {
        // Shift
        if modifiers & 0x01 != 0 {
            postKeyEvent(keyCode: 56, keyDown: keyDown, modifiers: modifiers) // kVK_Shift
        }
        // Control
        if modifiers & 0x02 != 0 {
            postKeyEvent(keyCode: 59, keyDown: keyDown, modifiers: modifiers) // kVK_Control
        }
        // Option
        if modifiers & 0x04 != 0 {
            postKeyEvent(keyCode: 58, keyDown: keyDown, modifiers: modifiers) // kVK_Option
        }
        // Command
        if modifiers & 0x08 != 0 {
            postKeyEvent(keyCode: 55, keyDown: keyDown, modifiers: modifiers) // kVK_Command
        }
    }

    private func cgButton(for button: MouseClick.Button) -> CGMouseButton {
        switch button {
        case .left: return .left
        case .right: return .right
        case .middle: return .center
        }
    }

    private func buttonDownType(for button: MouseClick.Button) -> CGEventType {
        switch button {
        case .left: return .leftMouseDown
        case .right: return .rightMouseDown
        case .middle: return .otherMouseDown
        }
    }

    private func buttonUpType(for button: MouseClick.Button) -> CGEventType {
        switch button {
        case .left: return .leftMouseUp
        case .right: return .rightMouseUp
        case .middle: return .otherMouseUp
        }
    }

    private func cgEventFlags(from modifiers: UInt32) -> CGEventFlags {
        var flags = CGEventFlags()

        if modifiers & 0x01 != 0 { flags.insert(.maskShift) }
        if modifiers & 0x02 != 0 { flags.insert(.maskControl) }
        if modifiers & 0x04 != 0 { flags.insert(.maskAlternate) }
        if modifiers & 0x08 != 0 { flags.insert(.maskCommand) }
        if modifiers & 0x10 != 0 { flags.insert(.maskAlphaShift) }
        if modifiers & 0x20 != 0 { flags.insert(.maskSecondaryFn) }

        return flags
    }
}
