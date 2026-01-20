import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct MacroFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var macros: [Macro] = []
        public var isEditing: Bool = false
        public var editorState: MacroEditorState?

        public init() {
            self.macros = Self.loadMacros()
        }

        // MARK: - Persistence

        private static let macrosKey = "snap.macros"
        private static let persistence: PersistenceManager = UserDefaultsPersistence.shared

        static func loadMacros() -> [Macro] {
            persistence.load(forKey: macrosKey, default: Macro.defaults)
        }

        mutating func saveMacros() {
            Self.persistence.save(macros, forKey: Self.macrosKey)
        }
    }

    // MARK: - Editor State

    public struct MacroEditorState: Equatable {
        public var macro: Macro
        public var isNew: Bool

        public init(macro: Macro? = nil) {
            if let macro = macro {
                self.macro = macro
                self.isNew = false
            } else {
                self.macro = Macro(
                    name: "",
                    icon: "star.fill",
                    color: .blue,
                    size: .small,
                    keyCombo: KeyCombo(keyCodes: [], modifiers: 0)
                )
                self.isNew = true
            }
        }
    }

    // MARK: - Action

    public enum Action: Equatable, Sendable {
        case macroTapped(Macro)
        case macroLongPressed(Macro)
        case editModeToggled
        case macroDeleted(Macro)
        case macroMoved(from: IndexSet, to: Int)

        // Editor
        case addMacroTapped
        case editMacroTapped(Macro)
        case dismissEditor
        case saveMacro(Macro)

        // Editor field updates
        case updateMacroName(String)
        case updateMacroIcon(String)
        case updateMacroColor(MacroColor)
        case updateMacroSize(MacroSize)
        case updateMacroKeyCombo(KeyCombo)

        // Reset
        case resetToDefaults
        case confirmResetToDefaults
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .macroTapped(let macro):
                guard !state.isEditing else {
                    return .send(.editMacroTapped(macro))
                }

                return .run { _ in
                    await client.sendKeyCombo(
                        macro.keyCombo.keyCodes,
                        macro.keyCombo.modifiers
                    )
                }

            case .macroLongPressed(let macro):
                return .send(.editMacroTapped(macro))

            case .editModeToggled:
                state.isEditing.toggle()
                return .none

            case .macroDeleted(let macro):
                state.macros.removeAll { $0.id == macro.id }
                state.saveMacros()
                return .none

            case .macroMoved(let from, let to):
                state.macros.move(fromOffsets: from, toOffset: to)
                state.saveMacros()
                return .none

            case .addMacroTapped:
                state.editorState = MacroEditorState()
                return .none

            case .editMacroTapped(let macro):
                state.editorState = MacroEditorState(macro: macro)
                return .none

            case .dismissEditor:
                state.editorState = nil
                return .none

            case .saveMacro(let macro):
                if let index = state.macros.firstIndex(where: { $0.id == macro.id }) {
                    state.macros[index] = macro
                } else {
                    state.macros.append(macro)
                }
                state.editorState = nil
                state.saveMacros()
                return .none

            case .updateMacroName(let name):
                state.editorState?.macro.name = name
                return .none

            case .updateMacroIcon(let icon):
                state.editorState?.macro.icon = icon
                return .none

            case .updateMacroColor(let color):
                state.editorState?.macro.color = color
                return .none

            case .updateMacroSize(let size):
                state.editorState?.macro.size = size
                return .none

            case .updateMacroKeyCombo(let keyCombo):
                state.editorState?.macro.keyCombo = keyCombo
                return .none

            case .resetToDefaults:
                // This action is just for showing confirmation
                return .none

            case .confirmResetToDefaults:
                state.macros = Macro.defaults
                state.saveMacros()
                return .none
            }
        }
    }
}
