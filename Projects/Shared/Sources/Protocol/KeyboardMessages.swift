import Foundation

// MARK: - ModifierFlags

/// 키보드 수정자(모디파이어) 플래그.
///
/// 비트마스크로 여러 수정자를 조합할 수 있습니다.
///
/// ## 사용 예제
/// ```swift
/// // Command + Shift 조합
/// let mods: ModifierFlags = [.command, .shift]
///
/// // 원시 값으로 생성
/// let mods = ModifierFlags(rawValue: 0x09)  // Command + Shift
/// ```
///
/// ## 비트 맵
/// - Shift: 0x01
/// - Control: 0x02
/// - Option: 0x04
/// - Command: 0x08
/// - CapsLock: 0x10
/// - Function: 0x20
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

/// 키보드 키 이벤트 메시지.
///
/// 단일 키 입력을 전달합니다.
/// TCP로 전송되어 모든 키 입력이 순서대로 전달됨을 보장합니다.
///
/// ## 사용 예제
/// ```swift
/// // Return 키 누르기
/// let returnKey = KeyEvent(keyCode: 36, action: .press, modifiers: 0)
///
/// // Command + A (전체 선택)
/// let selectAll = KeyEvent(
///     keyCode: 0,  // 'A' key
///     action: .press,
///     modifiers: ModifierFlags.command.rawValue
/// )
/// ```
public struct KeyEvent: Codable, Sendable, Equatable {
    /// 키 동작
    public enum Action: Int, Codable, Sendable, CaseIterable {
        /// 키 누름
        case down = 0
        /// 키 뗌
        case up = 1
        /// 키 누르고 떼기 (press = down + up)
        case press = 2
    }

    /// macOS 가상 키 코드
    public var keyCode: UInt32

    /// 수행할 동작
    public var action: Action

    /// 수정자 플래그 (ModifierFlags의 rawValue)
    public var modifiers: UInt32

    /// 입력 문자 (텍스트 입력용, 선택적)
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

/// 단축키 조합 메시지 (매크로용).
///
/// 여러 키를 동시에 누른 것처럼 전송합니다.
/// 매크로 실행이나 복잡한 단축키에 사용됩니다.
///
/// ## 사용 예제
/// ```swift
/// // Command + Shift + 4 (스크린샷 영역 선택)
/// let screenshot = KeyCombo(
///     keyCodes: [21],  // '4' key
///     modifiers: (ModifierFlags.command.rawValue | ModifierFlags.shift.rawValue)
/// )
///
/// // Mission Control (Control + ↑)
/// let missionControl = KeyCombo(
///     keyCodes: [126],  // Up Arrow
///     modifiers: ModifierFlags.control.rawValue
/// )
/// ```
public struct KeyCombo: Codable, Sendable, Equatable {
    /// 동시에 누를 키 코드들
    public var keyCodes: [UInt32]

    /// 수정자 플래그 (ModifierFlags의 rawValue)
    public var modifiers: UInt32

    public init(keyCodes: [UInt32] = [], modifiers: UInt32 = 0) {
        self.keyCodes = keyCodes
        self.modifiers = modifiers
    }
}
