import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct MacroFeature {
    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var macros: [Macro] = []
        public var groups: [MacroGroup] = []
        public var isEditing: Bool = false
        public var editorState: MacroEditorState?
        public var groupEditorState: MacroGroupEditorState?

        public init() {
            self.macros = Self.loadMacros()
            self.groups = Self.loadGroups()
        }

        // MARK: - Computed Properties

        /// 그룹에 속하지 않은 매크로
        public var ungroupedMacros: [Macro] {
            macros.filter { $0.groupId == nil }
        }

        // MARK: - Persistence

        private static let macrosKey = "snap.macros"
        private static let groupsKey = "snap.macro.groups"
        private static let persistence: PersistenceManager = UserDefaultsPersistence.shared

        static func loadMacros() -> [Macro] {
            persistence.load(forKey: macrosKey, default: Macro.defaults)
        }

        static func loadGroups() -> [MacroGroup] {
            persistence.load(forKey: groupsKey, default: [])
        }

        mutating func saveMacros() {
            Self.persistence.save(macros, forKey: Self.macrosKey)
        }

        mutating func saveGroups() {
            Self.persistence.save(groups, forKey: Self.groupsKey)
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

    // MARK: - Group Editor State

    public struct MacroGroupEditorState: Equatable {
        public var group: MacroGroup
        public var isNew: Bool

        public init(group: MacroGroup? = nil) {
            if let group = group {
                self.group = group
                self.isNew = false
            } else {
                self.group = MacroGroup(name: "", icon: "folder.fill")
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
        case updateMacroGroupId(UUID?)

        // Reset
        case resetToDefaults
        case confirmResetToDefaults

        // Group actions
        case groupToggled(MacroGroup)
        case addGroupTapped
        case editGroupTapped(MacroGroup)
        case dismissGroupEditor
        case saveGroup(MacroGroup)
        case deleteGroup(MacroGroup)
        case groupMoved(from: IndexSet, to: Int)
        case moveMacroToGroup(macro: Macro, groupId: UUID?)

        // Group editor field updates
        case updateGroupName(String)
        case updateGroupIcon(String)
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

            case .updateMacroGroupId(let groupId):
                state.editorState?.macro.groupId = groupId
                return .none

            case .resetToDefaults:
                // This action is just for showing confirmation
                return .none

            case .confirmResetToDefaults:
                state.macros = Macro.defaults
                state.groups = []
                state.saveMacros()
                state.saveGroups()
                return .none

            // MARK: - Group Actions

            case .groupToggled(let group):
                if let index = state.groups.firstIndex(where: { $0.id == group.id }) {
                    state.groups[index].isExpanded.toggle()
                    state.saveGroups()
                }
                return .none

            case .addGroupTapped:
                state.groupEditorState = MacroGroupEditorState()
                return .none

            case .editGroupTapped(let group):
                state.groupEditorState = MacroGroupEditorState(group: group)
                return .none

            case .dismissGroupEditor:
                state.groupEditorState = nil
                return .none

            case .saveGroup(let group):
                if let index = state.groups.firstIndex(where: { $0.id == group.id }) {
                    state.groups[index] = group
                } else {
                    state.groups.append(group)
                }
                state.groupEditorState = nil
                state.saveGroups()
                return .none

            case .deleteGroup(let group):
                // 그룹 내 매크로들의 groupId를 nil로 설정 (그룹 해제)
                for index in state.macros.indices where state.macros[index].groupId == group.id {
                    state.macros[index].groupId = nil
                }
                state.groups.removeAll { $0.id == group.id }
                state.saveMacros()
                state.saveGroups()
                return .none

            case .groupMoved(let from, let to):
                state.groups.move(fromOffsets: from, toOffset: to)
                state.saveGroups()
                return .none

            case .moveMacroToGroup(let macro, let groupId):
                if let index = state.macros.firstIndex(where: { $0.id == macro.id }) {
                    state.macros[index].groupId = groupId
                    state.saveMacros()
                }
                return .none

            case .updateGroupName(let name):
                state.groupEditorState?.group.name = name
                return .none

            case .updateGroupIcon(let icon):
                state.groupEditorState?.group.icon = icon
                return .none
            }
        }
    }
}
