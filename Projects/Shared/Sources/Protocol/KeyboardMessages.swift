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

    // MARK: - Virtual Key Codes (macOS)

    /// 모디파이어 키의 가상 키코드
    public enum VirtualKeyCode: UInt32 {
        case shift = 56     // kVK_Shift
        case control = 59   // kVK_Control
        case option = 58    // kVK_Option
        case command = 55   // kVK_Command
        case capsLock = 57  // kVK_CapsLock
        case function = 63  // kVK_Function
    }

    /// 활성화된 모디파이어들의 가상 키코드 배열
    public var virtualKeyCodes: [UInt32] {
        var codes: [UInt32] = []
        if contains(.shift) { codes.append(VirtualKeyCode.shift.rawValue) }
        if contains(.control) { codes.append(VirtualKeyCode.control.rawValue) }
        if contains(.option) { codes.append(VirtualKeyCode.option.rawValue) }
        if contains(.command) { codes.append(VirtualKeyCode.command.rawValue) }
        if contains(.capsLock) { codes.append(VirtualKeyCode.capsLock.rawValue) }
        if contains(.function) { codes.append(VirtualKeyCode.function.rawValue) }
        return codes
    }
}

#if os(macOS)
import CoreGraphics

public extension ModifierFlags {
    /// CGEventFlags로 변환 (macOS 전용)
    var cgEventFlags: CGEventFlags {
        var flags = CGEventFlags()
        if contains(.shift) { flags.insert(.maskShift) }
        if contains(.control) { flags.insert(.maskControl) }
        if contains(.option) { flags.insert(.maskAlternate) }
        if contains(.command) { flags.insert(.maskCommand) }
        if contains(.capsLock) { flags.insert(.maskAlphaShift) }
        if contains(.function) { flags.insert(.maskSecondaryFn) }
        return flags
    }

    /// CGEventFlags에서 ModifierFlags 생성 (macOS 전용)
    init(cgEventFlags: CGEventFlags) {
        var rawValue: UInt32 = 0
        if cgEventFlags.contains(.maskShift) { rawValue |= ModifierFlags.shift.rawValue }
        if cgEventFlags.contains(.maskControl) { rawValue |= ModifierFlags.control.rawValue }
        if cgEventFlags.contains(.maskAlternate) { rawValue |= ModifierFlags.option.rawValue }
        if cgEventFlags.contains(.maskCommand) { rawValue |= ModifierFlags.command.rawValue }
        if cgEventFlags.contains(.maskAlphaShift) { rawValue |= ModifierFlags.capsLock.rawValue }
        if cgEventFlags.contains(.maskSecondaryFn) { rawValue |= ModifierFlags.function.rawValue }
        self.init(rawValue: rawValue)
    }
}
#endif

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
