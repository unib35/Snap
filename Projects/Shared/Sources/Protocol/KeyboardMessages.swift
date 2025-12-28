import Foundation

// MARK: - Modifier Flags

/// 키보드 수정자 플래그
public struct ModifierFlags: OptionSet, Codable, Sendable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let shift = ModifierFlags(rawValue: 0x01)
    public static let control = ModifierFlags(rawValue: 0x02)
    public static let option = ModifierFlags(rawValue: 0x04)
    public static let command = ModifierFlags(rawValue: 0x08)
    public static let capsLock = ModifierFlags(rawValue: 0x10)
    public static let function = ModifierFlags(rawValue: 0x20)
}

// MARK: - KeyEvent

/// 키 이벤트
public struct KeyEvent: Codable, Sendable, Equatable {
    public enum Action: Int, Codable, Sendable, CaseIterable {
        case down = 0
        case up = 1
        case press = 2
    }

    public var keyCode: UInt32
    public var action: Action
    public var modifiers: UInt32
    public var character: String

    public init(
        keyCode: UInt32 = 0,
        action: Action = .press,
        modifiers: UInt32 = 0,
        character: String = ""
    ) {
        self.keyCode = keyCode
        self.action = action
        self.modifiers = modifiers
        self.character = character
    }
}

// MARK: - KeyCombo

/// 단축키 조합 (매크로용)
public struct KeyCombo: Codable, Sendable, Equatable {
    public var keyCodes: [UInt32]
    public var modifiers: UInt32

    public init(keyCodes: [UInt32] = [], modifiers: UInt32 = 0) {
        self.keyCodes = keyCodes
        self.modifiers = modifiers
    }
}
