import ComposableArchitecture
import Shared

@Reducer
public struct KeyboardFeature {
    @ObservableState
    public struct State: Equatable {
        public var inputText: String = ""
        public var activeModifiers: ModifierFlags = []
        public var isShiftLocked: Bool = false
        public var isControlLocked: Bool = false
        public var isOptionLocked: Bool = false
        public var isCommandLocked: Bool = false

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        // Text Input
        case textChanged(String)
        case submitText
        case clearText

        // Modifier Keys
        case shiftTapped
        case controlTapped
        case optionTapped
        case commandTapped
        case shiftDoubleTapped
        case controlDoubleTapped
        case optionDoubleTapped
        case commandDoubleTapped
        case clearModifiers

        // Special Keys
        case returnPressed
        case deletePressed
        case escapePressed
        case tabPressed
        case spacePressed
        case arrowPressed(ArrowDirection)

        // Function Keys
        case functionKeyPressed(Int)
    }

    public enum ArrowDirection: Equatable, Sendable {
        case up
        case down
        case left
        case right

        var keyCode: UInt32 {
            switch self {
            case .up: return 126
            case .down: return 125
            case .left: return 123
            case .right: return 124
            }
        }
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .textChanged(let text):
                let previousText = state.inputText
                state.inputText = text

                if text.count > previousText.count {
                    let newCharacters = String(text.suffix(text.count - previousText.count))
                    return .run { [modifiers = state.activeModifiers.rawValue] _ in
                        for char in newCharacters {
                            if let keyCode = keyCode(for: char) {
                                // 영문, 숫자, 특수문자: keyCode로 전송
                                await client.sendKeyEvent(keyCode, .press, modifiers)
                            } else {
                                // 한글 등 keyCode 매핑이 없는 문자: 텍스트로 직접 전송
                                await client.sendVoiceText(String(char), true)
                            }
                        }
                    }
                }
                return .none

            case .submitText:
                let text = state.inputText
                state.inputText = ""
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    for char in text {
                        if let keyCode = keyCode(for: char) {
                            // 영문, 숫자, 특수문자: keyCode로 전송
                            await client.sendKeyEvent(keyCode, .press, modifiers)
                        } else {
                            // 한글 등 keyCode 매핑이 없는 문자: 텍스트로 직접 전송
                            await client.sendVoiceText(String(char), true)
                        }
                    }
                    // Enter 키 전송
                    await client.sendKeyEvent(36, .press, 0)
                }

            case .clearText:
                state.inputText = ""
                return .none

            case .shiftTapped:
                if state.isShiftLocked {
                    state.isShiftLocked = false
                    state.activeModifiers.remove(.shift)
                } else {
                    state.activeModifiers.insert(.shift)
                }
                return .none

            case .controlTapped:
                if state.isControlLocked {
                    state.isControlLocked = false
                    state.activeModifiers.remove(.control)
                } else {
                    state.activeModifiers.insert(.control)
                }
                return .none

            case .optionTapped:
                if state.isOptionLocked {
                    state.isOptionLocked = false
                    state.activeModifiers.remove(.option)
                } else {
                    state.activeModifiers.insert(.option)
                }
                return .none

            case .commandTapped:
                if state.isCommandLocked {
                    state.isCommandLocked = false
                    state.activeModifiers.remove(.command)
                } else {
                    state.activeModifiers.insert(.command)
                }
                return .none

            case .shiftDoubleTapped:
                state.isShiftLocked.toggle()
                if state.isShiftLocked {
                    state.activeModifiers.insert(.shift)
                } else {
                    state.activeModifiers.remove(.shift)
                }
                return .none

            case .controlDoubleTapped:
                state.isControlLocked.toggle()
                if state.isControlLocked {
                    state.activeModifiers.insert(.control)
                } else {
                    state.activeModifiers.remove(.control)
                }
                return .none

            case .optionDoubleTapped:
                state.isOptionLocked.toggle()
                if state.isOptionLocked {
                    state.activeModifiers.insert(.option)
                } else {
                    state.activeModifiers.remove(.option)
                }
                return .none

            case .commandDoubleTapped:
                state.isCommandLocked.toggle()
                if state.isCommandLocked {
                    state.activeModifiers.insert(.command)
                } else {
                    state.activeModifiers.remove(.command)
                }
                return .none

            case .clearModifiers:
                state.activeModifiers = []
                state.isShiftLocked = false
                state.isControlLocked = false
                state.isOptionLocked = false
                state.isCommandLocked = false
                return .none

            case .returnPressed:
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(36, .press, modifiers)
                }

            case .deletePressed:
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(51, .press, modifiers)
                }

            case .escapePressed:
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(53, .press, modifiers)
                }

            case .tabPressed:
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(48, .press, modifiers)
                }

            case .spacePressed:
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(49, .press, modifiers)
                }

            case .arrowPressed(let direction):
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(direction.keyCode, .press, modifiers)
                }

            case .functionKeyPressed(let number):
                guard (1...12).contains(number) else { return .none }
                let keyCodes: [UInt32] = [122, 120, 99, 118, 96, 97, 98, 100, 101, 109, 103, 111]
                let keyCode = keyCodes[number - 1]
                return .run { [modifiers = state.activeModifiers.rawValue] _ in
                    await client.sendKeyEvent(keyCode, .press, modifiers)
                }
            }
        }
    }
}

// MARK: - Key Code Mapping

private func keyCode(for character: Character) -> UInt32? {
    let char = character.lowercased()
    let keyCodeMap: [Character: UInt32] = [
        "a": 0, "s": 1, "d": 2, "f": 3, "h": 4, "g": 5, "z": 6, "x": 7, "c": 8, "v": 9,
        "b": 11, "q": 12, "w": 13, "e": 14, "r": 15, "y": 16, "t": 17, "1": 18, "2": 19,
        "3": 20, "4": 21, "6": 22, "5": 23, "=": 24, "9": 25, "7": 26, "-": 27, "8": 28,
        "0": 29, "]": 30, "o": 31, "u": 32, "[": 33, "i": 34, "p": 35, "l": 37, "j": 38,
        "'": 39, "k": 40, ";": 41, "\\": 42, ",": 43, "/": 44, "n": 45, "m": 46, ".": 47,
        "`": 50, " ": 49
    ]
    return keyCodeMap[Character(char)]
}
