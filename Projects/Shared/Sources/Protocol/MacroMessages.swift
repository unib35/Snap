import Foundation

// MARK: - Macro

/// 매크로 정의
public struct Macro: Codable, Sendable, Equatable, Identifiable {
    public var id: UUID
    public var name: String
    public var icon: String
    public var color: MacroColor
    public var size: MacroSize
    public var keyCombo: KeyCombo

    public init(
        id: UUID = UUID(),
        name: String,
        icon: String,
        color: MacroColor = .blue,
        size: MacroSize = .small,
        keyCombo: KeyCombo
    ) {
        self.id = id
        self.name = name
        self.icon = icon
        self.color = color
        self.size = size
        self.keyCombo = keyCombo
    }
}

// MARK: - Macro Color

/// 매크로 색상
public enum MacroColor: String, Codable, Sendable, CaseIterable {
    case blue
    case purple
    case pink
    case red
    case orange
    case yellow
    case green
    case teal
    case gray
}

// MARK: - Macro Size

/// Bento Grid 크기
public enum MacroSize: String, Codable, Sendable, CaseIterable {
    case small      // 1x1
    case medium     // 2x1
    case large      // 2x2
}

// MARK: - Default Macros

public extension Macro {
    /// 기본 제공 매크로
    static let defaults: [Macro] = [
        // 편집
        Macro(
            name: "복사",
            icon: "doc.on.doc",
            color: .blue,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.c],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "붙여넣기",
            icon: "doc.on.clipboard",
            color: .blue,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.v],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "잘라내기",
            icon: "scissors",
            color: .blue,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.x],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "실행취소",
            icon: "arrow.uturn.backward",
            color: .orange,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.z],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "다시실행",
            icon: "arrow.uturn.forward",
            color: .orange,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.z],
                modifiers: ModifierFlags.command.rawValue | ModifierFlags.shift.rawValue
            )
        ),
        Macro(
            name: "전체선택",
            icon: "selection.pin.in.out",
            color: .purple,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.a],
                modifiers: ModifierFlags.command.rawValue
            )
        ),

        // 시스템
        Macro(
            name: "스크린샷",
            icon: "camera.viewfinder",
            color: .green,
            size: .medium,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.num4],
                modifiers: ModifierFlags.command.rawValue | ModifierFlags.shift.rawValue
            )
        ),
        Macro(
            name: "저장",
            icon: "square.and.arrow.down",
            color: .teal,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.s],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "새로고침",
            icon: "arrow.clockwise",
            color: .teal,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.r],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "찾기",
            icon: "magnifyingglass",
            color: .gray,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.f],
                modifiers: ModifierFlags.command.rawValue
            )
        ),

        // 탭 관리
        Macro(
            name: "새 탭",
            icon: "plus.square",
            color: .pink,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.t],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
        Macro(
            name: "탭 닫기",
            icon: "xmark.square",
            color: .red,
            size: .small,
            keyCombo: KeyCombo(
                keyCodes: [KeyCode.w],
                modifiers: ModifierFlags.command.rawValue
            )
        ),
    ]
}

// MARK: - Key Codes

/// macOS 키 코드
public enum KeyCode {
    public static let a: UInt32 = 0
    public static let s: UInt32 = 1
    public static let d: UInt32 = 2
    public static let f: UInt32 = 3
    public static let h: UInt32 = 4
    public static let g: UInt32 = 5
    public static let z: UInt32 = 6
    public static let x: UInt32 = 7
    public static let c: UInt32 = 8
    public static let v: UInt32 = 9
    public static let b: UInt32 = 11
    public static let q: UInt32 = 12
    public static let w: UInt32 = 13
    public static let e: UInt32 = 14
    public static let r: UInt32 = 15
    public static let y: UInt32 = 16
    public static let t: UInt32 = 17
    public static let num1: UInt32 = 18
    public static let num2: UInt32 = 19
    public static let num3: UInt32 = 20
    public static let num4: UInt32 = 21
    public static let num5: UInt32 = 23
    public static let num6: UInt32 = 22
    public static let num7: UInt32 = 26
    public static let num8: UInt32 = 28
    public static let num9: UInt32 = 25
    public static let num0: UInt32 = 29
    public static let space: UInt32 = 49
    public static let returnKey: UInt32 = 36
    public static let tab: UInt32 = 48
    public static let delete: UInt32 = 51
    public static let escape: UInt32 = 53
    public static let leftArrow: UInt32 = 123
    public static let rightArrow: UInt32 = 124
    public static let downArrow: UInt32 = 125
    public static let upArrow: UInt32 = 126
}
