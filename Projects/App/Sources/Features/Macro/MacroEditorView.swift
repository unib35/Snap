import ComposableArchitecture
import Shared
import SwiftUI

// MARK: - Macro Editor View

struct MacroEditorView: View {
    @Bindable var store: StoreOf<MacroFeature>

    var body: some View {
        if let editorState = store.editorState {
            NavigationStack {
                Form {
                    // Preview Section
                    previewSection(macro: editorState.macro)

                    // Name Section
                    nameSection(macro: editorState.macro)

                    // Icon Section
                    iconSection(macro: editorState.macro)

                    // Color Section
                    colorSection(macro: editorState.macro)

                    // Size Section
                    sizeSection(macro: editorState.macro)

                    // Key Combo Section
                    keyComboSection(macro: editorState.macro)
                }
                .navigationTitle(editorState.isNew ? "새 매크로" : "매크로 편집")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("취소") {
                            store.send(.dismissEditor)
                        }
                    }

                    ToolbarItem(placement: .confirmationAction) {
                        Button("저장") {
                            store.send(.saveMacro(editorState.macro))
                        }
                        .disabled(!isValidMacro(editorState.macro))
                    }
                }
            }
        }
    }

    private func isValidMacro(_ macro: Macro) -> Bool {
        !macro.name.trimmingCharacters(in: .whitespaces).isEmpty &&
        !macro.keyCombo.keyCodes.isEmpty
    }

    // MARK: - Preview Section

    @ViewBuilder
    private func previewSection(macro: Macro) -> some View {
        Section {
            HStack {
                Spacer()
                MacroPreviewButton(macro: macro)
                Spacer()
            }
            .listRowBackground(Color.clear)
        } header: {
            Text("미리보기")
        }
    }

    // MARK: - Name Section

    @ViewBuilder
    private func nameSection(macro: Macro) -> some View {
        Section {
            TextField("매크로 이름", text: Binding(
                get: { macro.name },
                set: { store.send(.updateMacroName($0)) }
            ))
        } header: {
            Text("이름")
        }
    }

    // MARK: - Icon Section

    @ViewBuilder
    private func iconSection(macro: Macro) -> some View {
        Section {
            IconPickerView(
                selectedIcon: macro.icon,
                color: macro.color.color
            ) { icon in
                store.send(.updateMacroIcon(icon))
            }
        } header: {
            Text("아이콘")
        }
    }

    // MARK: - Color Section

    @ViewBuilder
    private func colorSection(macro: Macro) -> some View {
        Section {
            ColorPickerView(selectedColor: macro.color) { color in
                store.send(.updateMacroColor(color))
            }
        } header: {
            Text("색상")
        }
    }

    // MARK: - Size Section

    @ViewBuilder
    private func sizeSection(macro: Macro) -> some View {
        Section {
            Picker("크기", selection: Binding(
                get: { macro.size },
                set: { store.send(.updateMacroSize($0)) }
            )) {
                ForEach(MacroSize.allCases, id: \.self) { size in
                    Text(size.displayName).tag(size)
                }
            }
            .pickerStyle(.segmented)
        } header: {
            Text("크기")
        } footer: {
            Text("Small: 1x1, Medium: 2x1, Large: 2x2")
        }
    }

    // MARK: - Key Combo Section

    @ViewBuilder
    private func keyComboSection(macro: Macro) -> some View {
        Section {
            KeyComboPickerView(keyCombo: macro.keyCombo) { keyCombo in
                store.send(.updateMacroKeyCombo(keyCombo))
            }
        } header: {
            Text("단축키")
        } footer: {
            Text("Mac에서 실행할 키 조합을 선택하세요")
        }
    }
}

// MARK: - Macro Preview Button

struct MacroPreviewButton: View {
    let macro: Macro

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: macro.icon)
                .font(.system(size: macro.size == .large ? 32 : 24))
                .foregroundStyle(.white)

            Text(macro.name.isEmpty ? "매크로" : macro.name)
                .font(macro.size == .small ? .caption2 : .caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(width: previewWidth, height: macro.size.height)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(macro.color.gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: macro.color.color.opacity(0.3), radius: 8, y: 4)
    }

    private var previewWidth: CGFloat {
        switch macro.size {
        case .small: return 80
        case .medium, .large: return 172
        }
    }
}

// MARK: - Icon Picker View

struct IconPickerView: View {
    let selectedIcon: String
    let color: Color
    let onSelect: (String) -> Void

    private let icons = [
        // Common actions
        "star.fill", "heart.fill", "bolt.fill", "flame.fill",
        "doc.on.doc", "doc.on.clipboard", "scissors", "arrow.uturn.backward",
        "arrow.uturn.forward", "selection.pin.in.out", "magnifyingglass", "square.and.arrow.down",
        // Media
        "play.fill", "pause.fill", "stop.fill", "backward.fill",
        "forward.fill", "speaker.wave.3.fill", "mic.fill", "video.fill",
        // System
        "camera.viewfinder", "arrow.clockwise", "gear", "terminal",
        "folder.fill", "trash.fill", "lock.fill", "key.fill",
        // Tabs & Windows
        "plus.square", "xmark.square", "rectangle.split.2x1", "macwindow",
        "square.on.square", "rectangle.stack", "sidebar.left", "sidebar.right",
        // Arrows
        "arrow.up", "arrow.down", "arrow.left", "arrow.right",
        "arrow.up.arrow.down", "arrow.left.arrow.right", "chevron.up", "chevron.down",
        // Code
        "curlybraces", "chevron.left.forwardslash.chevron.right", "terminal.fill", "hammer.fill",
        "wrench.fill", "paintbrush.fill", "textformat", "list.bullet",
    ]

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 6)

    var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    onSelect(icon)
                } label: {
                    Image(systemName: icon)
                        .font(.title2)
                        .foregroundStyle(selectedIcon == icon ? .white : color)
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedIcon == icon ? color : SnapColors.tertiarySystemBackground)
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Color Picker View

struct ColorPickerView: View {
    let selectedColor: MacroColor
    let onSelect: (MacroColor) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(MacroColor.allCases, id: \.self) { color in
                Button {
                    onSelect(color)
                } label: {
                    Circle()
                        .fill(color.color.gradient)
                        .frame(width: 32, height: 32)
                        .overlay(
                            Circle()
                                .strokeBorder(.white, lineWidth: selectedColor == color ? 3 : 0)
                        )
                        .shadow(color: color.color.opacity(0.3), radius: 4)
                }
                .buttonStyle(.plain)
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Key Combo Picker View

struct KeyComboPickerView: View {
    let keyCombo: KeyCombo
    let onUpdate: (KeyCombo) -> Void

    @State private var showKeyPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Modifiers
            HStack(spacing: 8) {
                ModifierToggle(
                    label: "⌘",
                    isSelected: hasModifier(.command)
                ) {
                    toggleModifier(.command)
                }

                ModifierToggle(
                    label: "⌥",
                    isSelected: hasModifier(.option)
                ) {
                    toggleModifier(.option)
                }

                ModifierToggle(
                    label: "⌃",
                    isSelected: hasModifier(.control)
                ) {
                    toggleModifier(.control)
                }

                ModifierToggle(
                    label: "⇧",
                    isSelected: hasModifier(.shift)
                ) {
                    toggleModifier(.shift)
                }
            }

            // Key Selection
            Button {
                showKeyPicker = true
            } label: {
                HStack {
                    Text("키")
                        .foregroundStyle(.primary)

                    Spacer()

                    Text(keyDisplayName)
                        .foregroundStyle(SnapColors.textSecondary)

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            .sheet(isPresented: $showKeyPicker) {
                KeyPickerSheet(
                    selectedKeyCode: keyCombo.keyCodes.first,
                    onSelect: { keyCode in
                        var newCombo = keyCombo
                        newCombo.keyCodes = [keyCode]
                        onUpdate(newCombo)
                        showKeyPicker = false
                    }
                )
            }

            // Display current combo
            if !keyCombo.keyCodes.isEmpty {
                HStack {
                    Text("단축키:")
                        .font(.caption)
                        .foregroundStyle(SnapColors.textSecondary)

                    Text(fullComboDisplayName)
                        .font(.caption.monospaced())
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(SnapColors.tertiarySystemBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
            }
        }
    }

    private func hasModifier(_ flag: ModifierFlags) -> Bool {
        keyCombo.modifiers & flag.rawValue != 0
    }

    private func toggleModifier(_ flag: ModifierFlags) {
        var newCombo = keyCombo
        if hasModifier(flag) {
            newCombo.modifiers &= ~flag.rawValue
        } else {
            newCombo.modifiers |= flag.rawValue
        }
        onUpdate(newCombo)
    }

    private var keyDisplayName: String {
        guard let keyCode = keyCombo.keyCodes.first else {
            return "선택..."
        }
        return KeyCodeInfo.name(for: keyCode)
    }

    private var fullComboDisplayName: String {
        var parts: [String] = []

        if hasModifier(.command) { parts.append("⌘") }
        if hasModifier(.option) { parts.append("⌥") }
        if hasModifier(.control) { parts.append("⌃") }
        if hasModifier(.shift) { parts.append("⇧") }

        if let keyCode = keyCombo.keyCodes.first {
            parts.append(KeyCodeInfo.name(for: keyCode))
        }

        return parts.joined(separator: " + ")
    }
}

// MARK: - Modifier Toggle

struct ModifierToggle: View {
    let label: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(.title2)
                .frame(width: 44, height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isSelected ? Color.accentColor : SnapColors.tertiarySystemBackground)
                )
                .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Key Picker Sheet

struct KeyPickerSheet: View {
    let selectedKeyCode: UInt32?
    let onSelect: (UInt32) -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                Section("문자") {
                    ForEach(KeyCodeInfo.letterKeys, id: \.code) { key in
                        keyRow(key)
                    }
                }

                Section("숫자") {
                    ForEach(KeyCodeInfo.numberKeys, id: \.code) { key in
                        keyRow(key)
                    }
                }

                Section("기능키") {
                    ForEach(KeyCodeInfo.functionKeys, id: \.code) { key in
                        keyRow(key)
                    }
                }

                Section("방향키") {
                    ForEach(KeyCodeInfo.arrowKeys, id: \.code) { key in
                        keyRow(key)
                    }
                }

                Section("기타") {
                    ForEach(KeyCodeInfo.otherKeys, id: \.code) { key in
                        keyRow(key)
                    }
                }
            }
            .navigationTitle("키 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        dismiss()
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func keyRow(_ key: KeyCodeInfo) -> some View {
        Button {
            onSelect(key.code)
        } label: {
            HStack {
                Text(key.name)
                    .foregroundStyle(.primary)

                Spacer()

                if selectedKeyCode == key.code {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Color.accentColor)
                }
            }
        }
    }
}

// MARK: - Key Code Info

struct KeyCodeInfo: Equatable {
    let code: UInt32
    let name: String

    static func name(for code: UInt32) -> String {
        allKeys.first { $0.code == code }?.name ?? "Unknown"
    }

    static let letterKeys: [KeyCodeInfo] = [
        KeyCodeInfo(code: KeyCode.a, name: "A"),
        KeyCodeInfo(code: KeyCode.b, name: "B"),
        KeyCodeInfo(code: KeyCode.c, name: "C"),
        KeyCodeInfo(code: KeyCode.d, name: "D"),
        KeyCodeInfo(code: KeyCode.e, name: "E"),
        KeyCodeInfo(code: KeyCode.f, name: "F"),
        KeyCodeInfo(code: KeyCode.g, name: "G"),
        KeyCodeInfo(code: KeyCode.h, name: "H"),
        KeyCodeInfo(code: 34, name: "I"),
        KeyCodeInfo(code: 38, name: "J"),
        KeyCodeInfo(code: 40, name: "K"),
        KeyCodeInfo(code: 37, name: "L"),
        KeyCodeInfo(code: 46, name: "M"),
        KeyCodeInfo(code: 45, name: "N"),
        KeyCodeInfo(code: 31, name: "O"),
        KeyCodeInfo(code: 35, name: "P"),
        KeyCodeInfo(code: KeyCode.q, name: "Q"),
        KeyCodeInfo(code: KeyCode.r, name: "R"),
        KeyCodeInfo(code: KeyCode.s, name: "S"),
        KeyCodeInfo(code: KeyCode.t, name: "T"),
        KeyCodeInfo(code: 32, name: "U"),
        KeyCodeInfo(code: KeyCode.v, name: "V"),
        KeyCodeInfo(code: KeyCode.w, name: "W"),
        KeyCodeInfo(code: KeyCode.x, name: "X"),
        KeyCodeInfo(code: KeyCode.y, name: "Y"),
        KeyCodeInfo(code: KeyCode.z, name: "Z"),
    ]

    static let numberKeys: [KeyCodeInfo] = [
        KeyCodeInfo(code: KeyCode.num0, name: "0"),
        KeyCodeInfo(code: KeyCode.num1, name: "1"),
        KeyCodeInfo(code: KeyCode.num2, name: "2"),
        KeyCodeInfo(code: KeyCode.num3, name: "3"),
        KeyCodeInfo(code: KeyCode.num4, name: "4"),
        KeyCodeInfo(code: KeyCode.num5, name: "5"),
        KeyCodeInfo(code: KeyCode.num6, name: "6"),
        KeyCodeInfo(code: KeyCode.num7, name: "7"),
        KeyCodeInfo(code: KeyCode.num8, name: "8"),
        KeyCodeInfo(code: KeyCode.num9, name: "9"),
    ]

    static let functionKeys: [KeyCodeInfo] = [
        KeyCodeInfo(code: 122, name: "F1"),
        KeyCodeInfo(code: 120, name: "F2"),
        KeyCodeInfo(code: 99, name: "F3"),
        KeyCodeInfo(code: 118, name: "F4"),
        KeyCodeInfo(code: 96, name: "F5"),
        KeyCodeInfo(code: 97, name: "F6"),
        KeyCodeInfo(code: 98, name: "F7"),
        KeyCodeInfo(code: 100, name: "F8"),
        KeyCodeInfo(code: 101, name: "F9"),
        KeyCodeInfo(code: 109, name: "F10"),
        KeyCodeInfo(code: 103, name: "F11"),
        KeyCodeInfo(code: 111, name: "F12"),
    ]

    static let arrowKeys: [KeyCodeInfo] = [
        KeyCodeInfo(code: KeyCode.upArrow, name: "↑"),
        KeyCodeInfo(code: KeyCode.downArrow, name: "↓"),
        KeyCodeInfo(code: KeyCode.leftArrow, name: "←"),
        KeyCodeInfo(code: KeyCode.rightArrow, name: "→"),
    ]

    static let otherKeys: [KeyCodeInfo] = [
        KeyCodeInfo(code: KeyCode.space, name: "Space"),
        KeyCodeInfo(code: KeyCode.returnKey, name: "Return"),
        KeyCodeInfo(code: KeyCode.tab, name: "Tab"),
        KeyCodeInfo(code: KeyCode.delete, name: "Delete"),
        KeyCodeInfo(code: KeyCode.escape, name: "Escape"),
    ]

    static let allKeys: [KeyCodeInfo] = letterKeys + numberKeys + functionKeys + arrowKeys + otherKeys
}

// MARK: - MacroSize Extension

extension MacroSize {
    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }
}
