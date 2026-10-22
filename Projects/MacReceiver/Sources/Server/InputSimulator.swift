import Foundation
import CoreGraphics
import Shared

/// 입력 시뮬레이터 (마우스, 키보드 이벤트 주입)
///
/// Input state and event posting are owned by the main actor.
@MainActor
public final class InputSimulator {
    // MARK: - Singleton

    public static let shared = InputSimulator()

    private var pressedButtons: [MouseClick.Button] = []
    private var pressedKeys: Set<CGKeyCode> = []
    private let postEvent: (CGEvent) -> Void
    private let mouseLocation: () -> CGPoint

    init(
        postEvent: @escaping (CGEvent) -> Void = { $0.post(tap: .cghidEventTap) },
        mouseLocation: @escaping () -> CGPoint = { CGEvent(source: nil)?.location ?? .zero }
    ) {
        self.postEvent = postEvent
        self.mouseLocation = mouseLocation
    }

    public func releaseAllInputs() {
        for button in pressedButtons {
            postMouseEvent(type: buttonUpType(for: button), button: cgButton(for: button), at: currentMouseLocation())
        }
        for key in pressedKeys { postKeyEvent(keyCode: key, keyDown: false, modifiers: 0) }
        pressedButtons.removeAll()
        pressedKeys.removeAll()
    }

    // MARK: - Mouse

    /// 마우스 이동 (상대 좌표)
    public func moveMouse(deltaX: CGFloat, deltaY: CGFloat) {
        guard deltaX.isFinite, deltaY.isFinite,
              abs(deltaX) <= 1_000_000, abs(deltaY) <= 1_000_000 else { return }
        let current = currentMouseLocation()
        let button = pressedButtons.last
        let type: CGEventType
        switch button {
        case .left: type = .leftMouseDragged
        case .right: type = .rightMouseDragged
        case .middle: type = .otherMouseDragged
        case nil: type = .mouseMoved
        }
        guard let event = CGEvent(
            mouseEventSource: nil,
            mouseType: type,
            mouseCursorPosition: CGPoint(x: current.x + deltaX, y: current.y + deltaY),
            mouseButton: button.map(cgButton(for:)) ?? .left
        ) else { return }

        // 상대 좌표로 이동
        event.setIntegerValueField(.mouseEventDeltaX, value: Int64(deltaX))
        event.setIntegerValueField(.mouseEventDeltaY, value: Int64(deltaY))
        postEvent(event)
    }

    /// 마우스 클릭
    public func mouseClick(button: MouseClick.Button, action: MouseClick.Action) {
        let location = currentMouseLocation()

        switch action {
        case .down:
            if !pressedButtons.contains(button) { pressedButtons.append(button) }
            postMouseEvent(type: buttonDownType(for: button), button: cgButton(for: button), at: location)
        case .up:
            pressedButtons.removeAll { $0 == button }
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
        guard deltaX.isFinite, deltaY.isFinite,
              let x = Int32(exactly: deltaX.rounded(.towardZero)),
              let y = Int32(exactly: deltaY.rounded(.towardZero)) else { return }
        guard let event = CGEvent(
            scrollWheelEvent2Source: nil,
            units: .pixel,
            wheelCount: 2,
            wheel1: y,
            wheel2: x,
            wheel3: 0
        ) else { return }

        postEvent(event)
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
        guard let code = CGKeyCode(exactly: keyCode) else { return }
        switch action {
        case .down:
            pressedKeys.insert(code)
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: true, modifiers: modifiers)
        case .up:
            pressedKeys.remove(code)
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: false, modifiers: modifiers)
        case .press:
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: true, modifiers: modifiers)
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: false, modifiers: modifiers)
        }
    }

    /// 키 조합 실행
    public func executeKeyCombo(keyCodes: [UInt32], modifiers: UInt32) {
        guard keyCodes.allSatisfy({ CGKeyCode(exactly: $0) != nil }) else { return }
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
        let codeUnits = Array(string.utf16)
        guard !codeUnits.isEmpty else { return }

        // CGEventKeyboardSetUnicodeString을 사용하여 유니코드 문자 입력
        guard let keyDownEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: true),
              let keyUpEvent = CGEvent(keyboardEventSource: nil, virtualKey: 0, keyDown: false) else {
            return
        }

        codeUnits.withUnsafeBufferPointer { buffer in
            guard let base = buffer.baseAddress else { return }
            keyDownEvent.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
            keyUpEvent.keyboardSetUnicodeString(stringLength: buffer.count, unicodeString: base)
        }
        postEvent(keyDownEvent)
        postEvent(keyUpEvent)
    }

    // MARK: - Private Helpers

    private func currentMouseLocation() -> CGPoint {
        mouseLocation()
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
        postEvent(event)
    }

    private func postKeyEvent(keyCode: CGKeyCode, keyDown: Bool, modifiers: UInt32) {
        guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: keyDown) else {
            return
        }

        let flags = ModifierFlags(rawValue: modifiers)
        event.flags = flags.cgEventFlags
        postEvent(event)
    }

    private func setModifiers(_ modifiers: UInt32, keyDown: Bool) {
        let flags = ModifierFlags(rawValue: modifiers)
        for keyCode in flags.virtualKeyCodes {
            postKeyEvent(keyCode: CGKeyCode(keyCode), keyDown: keyDown, modifiers: keyDown ? modifiers : 0)
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
}
