import ComposableArchitecture
import Testing
@testable import App
import Shared

// MARK: - Text Input Tests

@Suite("텍스트 입력 테스트")
struct TextInputTests {
    @Test("텍스트 변경 시 상태 업데이트")
    func textChanged() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { _, _, _ in }
            $0.connectionClient.sendVoiceText = { _, _ in }
        }

        await store.send(.textChanged("a")) {
            $0.inputText = "a"
        }
    }

    @Test("영문 입력 시 키 이벤트 전송")
    func textChangedSendsKeyEvent() async {
        let sentKeyEvents = LockIsolated<[(UInt32, KeyEvent.Action, UInt32)]>([])
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvents.withValue { $0.append((keyCode, action, modifiers)) }
            }
            $0.connectionClient.sendVoiceText = { _, _ in }
        }

        await store.send(.textChanged("ab")) {
            $0.inputText = "ab"
        }

        // 'a'와 'b'에 대한 키 이벤트가 전송되어야 함
        #expect(sentKeyEvents.value.count == 2)
        #expect(sentKeyEvents.value[0].0 == 0) // 'a' keyCode
        #expect(sentKeyEvents.value[1].0 == 11) // 'b' keyCode
    }

    @Test("텍스트 제출 시 입력 초기화 및 Enter 전송")
    func submitText() async {
        var state = KeyboardFeature.State()
        state.inputText = "test"

        let sentKeyEvents = LockIsolated<[(UInt32, KeyEvent.Action, UInt32)]>([])
        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvents.withValue { $0.append((keyCode, action, modifiers)) }
            }
            $0.connectionClient.sendVoiceText = { _, _ in }
        }

        await store.send(.submitText) {
            $0.inputText = ""
        }

        // 마지막에 Enter(36) 키가 전송되어야 함
        #expect(sentKeyEvents.value.last?.0 == 36)
    }

    @Test("텍스트 클리어")
    func clearText() async {
        var state = KeyboardFeature.State()
        state.inputText = "test"

        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        }

        await store.send(.clearText) {
            $0.inputText = ""
        }
    }
}

// MARK: - Modifier Key Tests

@Suite("모디파이어 키 테스트")
struct ModifierKeyTests {
    @Test("Shift 탭 - 활성화")
    func shiftTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.shiftTapped) {
            $0.activeModifiers = [.shift]
        }
    }

    @Test("Shift 탭 - 잠금 상태에서 해제")
    func shiftTappedWhileLocked() async {
        var state = KeyboardFeature.State()
        state.isShiftLocked = true
        state.activeModifiers = [.shift]

        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        }

        await store.send(.shiftTapped) {
            $0.isShiftLocked = false
            $0.activeModifiers = []
        }
    }

    @Test("Control 탭")
    func controlTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.controlTapped) {
            $0.activeModifiers = [.control]
        }
    }

    @Test("Option 탭")
    func optionTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.optionTapped) {
            $0.activeModifiers = [.option]
        }
    }

    @Test("Command 탭")
    func commandTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.commandTapped) {
            $0.activeModifiers = [.command]
        }
    }

    @Test("Shift 더블탭 - 잠금")
    func shiftDoubleTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.shiftDoubleTapped) {
            $0.isShiftLocked = true
            $0.activeModifiers = [.shift]
        }
    }

    @Test("Shift 더블탭 - 잠금 해제")
    func shiftDoubleTappedUnlock() async {
        var state = KeyboardFeature.State()
        state.isShiftLocked = true
        state.activeModifiers = [.shift]

        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        }

        await store.send(.shiftDoubleTapped) {
            $0.isShiftLocked = false
            $0.activeModifiers = []
        }
    }

    @Test("Control 더블탭 - 잠금")
    func controlDoubleTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.controlDoubleTapped) {
            $0.isControlLocked = true
            $0.activeModifiers = [.control]
        }
    }

    @Test("Option 더블탭 - 잠금")
    func optionDoubleTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.optionDoubleTapped) {
            $0.isOptionLocked = true
            $0.activeModifiers = [.option]
        }
    }

    @Test("Command 더블탭 - 잠금")
    func commandDoubleTapped() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.commandDoubleTapped) {
            $0.isCommandLocked = true
            $0.activeModifiers = [.command]
        }
    }

    @Test("모디파이어 전체 초기화")
    func clearModifiers() async {
        var state = KeyboardFeature.State()
        state.activeModifiers = [.shift, .command]
        state.isShiftLocked = true
        state.isCommandLocked = true

        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        }

        await store.send(.clearModifiers) {
            $0.activeModifiers = []
            $0.isShiftLocked = false
            $0.isControlLocked = false
            $0.isOptionLocked = false
            $0.isCommandLocked = false
        }
    }

    @Test("복합 모디파이어 조합")
    func multipleModifiers() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.shiftTapped) {
            $0.activeModifiers = [.shift]
        }

        await store.send(.commandTapped) {
            $0.activeModifiers = [.shift, .command]
        }

        await store.send(.optionTapped) {
            $0.activeModifiers = [.shift, .command, .option]
        }
    }
}

// MARK: - Special Key Tests

@Suite("특수키 테스트")
struct SpecialKeyTests {
    @Test("Return 키")
    func returnPressed() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.returnPressed)

        #expect(sentKeyEvent.value?.0 == 36) // Return keyCode
        #expect(sentKeyEvent.value?.1 == .press)
    }

    @Test("Delete 키")
    func deletePressed() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.deletePressed)

        #expect(sentKeyEvent.value?.0 == 51) // Delete keyCode
    }

    @Test("Escape 키")
    func escapePressed() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.escapePressed)

        #expect(sentKeyEvent.value?.0 == 53) // Escape keyCode
    }

    @Test("Tab 키")
    func tabPressed() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.tabPressed)

        #expect(sentKeyEvent.value?.0 == 48) // Tab keyCode
    }

    @Test("Space 키")
    func spacePressed() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.spacePressed)

        #expect(sentKeyEvent.value?.0 == 49) // Space keyCode
    }

    @Test("특수키에 모디파이어 적용")
    func specialKeyWithModifiers() async {
        var state = KeyboardFeature.State()
        state.activeModifiers = [.command]

        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.deletePressed)

        #expect(sentKeyEvent.value?.0 == 51)
        #expect(sentKeyEvent.value?.2 == ModifierFlags.command.rawValue)
    }
}

// MARK: - Arrow Key Tests

@Suite("방향키 테스트")
struct ArrowKeyTests {
    @Test("위 방향키")
    func arrowUp() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.arrowPressed(.up))

        #expect(sentKeyEvent.value?.0 == 126)
    }

    @Test("아래 방향키")
    func arrowDown() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.arrowPressed(.down))

        #expect(sentKeyEvent.value?.0 == 125)
    }

    @Test("왼쪽 방향키")
    func arrowLeft() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.arrowPressed(.left))

        #expect(sentKeyEvent.value?.0 == 123)
    }

    @Test("오른쪽 방향키")
    func arrowRight() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.arrowPressed(.right))

        #expect(sentKeyEvent.value?.0 == 124)
    }

    @Test("방향키 + 모디파이어 조합")
    func arrowWithModifiers() async {
        var state = KeyboardFeature.State()
        state.activeModifiers = [.shift, .command]

        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: state) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.arrowPressed(.left))

        #expect(sentKeyEvent.value?.0 == 123)
        #expect(sentKeyEvent.value?.2 == (ModifierFlags.shift.rawValue | ModifierFlags.command.rawValue))
    }
}

// MARK: - Function Key Tests

@Suite("펑션키 테스트")
struct FunctionKeyTests {
    @Test("F1 키")
    func functionKeyF1() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.functionKeyPressed(1))

        #expect(sentKeyEvent.value?.0 == 122) // F1 keyCode
    }

    @Test("F12 키")
    func functionKeyF12() async {
        let sentKeyEvent = LockIsolated<(UInt32, KeyEvent.Action, UInt32)?>(nil)
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        } withDependencies: {
            $0.connectionClient.sendKeyEvent = { keyCode, action, modifiers in
                sentKeyEvent.setValue((keyCode, action, modifiers))
            }
        }

        await store.send(.functionKeyPressed(12))

        #expect(sentKeyEvent.value?.0 == 111) // F12 keyCode
    }

    @Test("유효하지 않은 펑션키 번호 무시")
    func invalidFunctionKey() async {
        let store = await TestStore(initialState: KeyboardFeature.State()) {
            KeyboardFeature()
        }

        await store.send(.functionKeyPressed(0))
        await store.send(.functionKeyPressed(13))
        // 아무 동작 없음
    }
}
