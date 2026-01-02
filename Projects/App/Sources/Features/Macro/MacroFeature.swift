import ComposableArchitecture
import Foundation
import Shared

@Reducer
public struct MacroFeature {
    @ObservableState
    public struct State: Equatable {
        public var macros: [Macro] = Macro.defaults
        public var isEditing: Bool = false
        public var selectedMacro: Macro?

        public init() {}
    }

    public enum Action: Equatable, Sendable {
        case macroTapped(Macro)
        case macroLongPressed(Macro)
        case editModeToggled
        case macroDeleted(Macro)
        case macroMoved(from: IndexSet, to: Int)
        case dismissEditor
        case saveMacro(Macro)
    }

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            let client = connectionClient

            switch action {
            case .macroTapped(let macro):
                guard !state.isEditing else {
                    state.selectedMacro = macro
                    return .none
                }

                return .run { _ in
                    await client.sendKeyCombo(
                        macro.keyCombo.keyCodes,
                        macro.keyCombo.modifiers
                    )
                }

            case .macroLongPressed(let macro):
                state.selectedMacro = macro
                return .none

            case .editModeToggled:
                state.isEditing.toggle()
                if !state.isEditing {
                    state.selectedMacro = nil
                }
                return .none

            case .macroDeleted(let macro):
                state.macros.removeAll { $0.id == macro.id }
                return .none

            case .macroMoved(let from, let to):
                state.macros.move(fromOffsets: from, toOffset: to)
                return .none

            case .dismissEditor:
                state.selectedMacro = nil
                return .none

            case .saveMacro(let macro):
                if let index = state.macros.firstIndex(where: { $0.id == macro.id }) {
                    state.macros[index] = macro
                } else {
                    state.macros.append(macro)
                }
                state.selectedMacro = nil
                return .none
            }
        }
    }
}
