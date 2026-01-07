import Foundation
import CoreGraphics
import Shared

/// 입력 시뮬레이터 (마우스, 키보드 이벤트 주입)
///
/// - Note: `@unchecked Sendable` - 상태를 갖지 않고 CGEvent API만 호출하므로 스레드 안전함
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

    /// 핀치 줌 (Cmd+/Cmd- 키 조합으로 구현)
    public func pinchZoom(scale: CGFloat, phase: Pinch.Phase) {
        // began/ended 단계에서는 무시 (changed에서만 처리)
        guard phase == .changed else { return }

        // scale > 1.0 = 확대 (Cmd+=), scale < 1.0 = 축소 (Cmd+-)
        if scale > 1.02 {
            // Cmd + = (확대)
            executeKeyCombo(keyCodes: [24], modifiers: 0x08) // 24 = kVK_ANSI_Equal
        } else if scale < 0.98 {
            // Cmd + - (축소)
            executeKeyCombo(keyCodes: [27], modifiers: 0x08) // 27 = kVK_ANSI_Minus
        }
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

    /// 텍스트 입력 (유니코드 문자열)
    public func typeText(_ text: String) {
        for character in text {
            typeCharacter(character)
        }
    }

    /// 단일 문자 입력
    private func typeCharacter(_ character: Character) {
        let string = String(character)
        guard let unicodeScalar = string.unicodeScalars.first else { return }

        // CGEventKeyboardSetUnicodeString을 사용하여 유니코드 문자 입력
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return
        }

        var unicodeChar = UniChar(unicodeScalar.value)
        keyDownEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)
        keyUpEvent.keyboardSetUnicodeString(stringLength: 1, unicodeString: &unicodeChar)

        keyDownEvent.post(tap: .cghidEventTap)
        keyUpEvent.post(tap: .cghidEventTap)
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
