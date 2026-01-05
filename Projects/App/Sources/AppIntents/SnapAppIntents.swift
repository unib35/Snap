import AppIntents
import Foundation
import Shared
import UIKit

// MARK: - Connect to Mac Intent

struct ConnectToMacIntent: AppIntent {
    static let title: LocalizedStringResource = "Mac에 연결"
    static let description = IntentDescription("Snap을 통해 Mac에 연결합니다.")

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        .result(dialog: "Mac에 연결을 시도합니다.")
    }
}

// MARK: - Run Macro Intent

struct RunMacroIntent: AppIntent {
    static let title: LocalizedStringResource = "매크로 실행"
    static let description = IntentDescription("저장된 매크로를 실행합니다.")

    @Parameter(title: "매크로")
    var macro: MacroEntity

    static var parameterSummary: some ParameterSummary {
        Summary("'\(\.$macro)' 매크로 실행")
    }

    static let openAppWhenRun: Bool = true

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        // URL을 통해 매크로 실행
        if let url = URL(string: "snap://macro/\(macro.id)") {
            await UIApplication.shared.open(url)
        }
        return .result(dialog: "\(macro.name) 매크로를 실행합니다.")
    }
}

// MARK: - Macro Entity

struct MacroEntity: AppEntity {
    static let typeDisplayRepresentation: TypeDisplayRepresentation = "매크로"

    static let defaultQuery = MacroEntityQuery()

    var id: String
    var name: String
    var icon: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(
            title: "\(name)",
            subtitle: nil,
            image: .init(systemName: icon)
        )
    }

    init(id: String, name: String, icon: String) {
        self.id = id
        self.name = name
        self.icon = icon
    }

    init(from macro: Macro) {
        self.id = macro.id.uuidString
        self.name = macro.name
        self.icon = macro.icon
    }
}

// MARK: - Macro Entity Query

struct MacroEntityQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [MacroEntity] {
        let macros = loadMacros()
        return macros
            .filter { identifiers.contains($0.id.uuidString) }
            .map { MacroEntity(from: $0) }
    }

    func suggestedEntities() async throws -> [MacroEntity] {
        let macros = loadMacros()
        return macros.map { MacroEntity(from: $0) }
    }

    func defaultResult() async -> MacroEntity? {
        let macros = loadMacros()
        return macros.first.map { MacroEntity(from: $0) }
    }

    private func loadMacros() -> [Macro] {
        let macrosKey = "snap.macros"
        guard let data = UserDefaults.standard.data(forKey: macrosKey),
              let macros = try? JSONDecoder().decode([Macro].self, from: data) else {
            return Macro.defaults
        }
        return macros
    }
}

// MARK: - App Shortcuts Provider

struct SnapAppShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: ConnectToMacIntent(),
            phrases: [
                "Mac 연결해줘 \(.applicationName)",
                "\(.applicationName)으로 Mac 연결",
                "\(.applicationName) 연결",
            ],
            shortTitle: "Mac 연결",
            systemImageName: "wifi"
        )

        AppShortcut(
            intent: RunMacroIntent(),
            phrases: [
                "\(.applicationName)에서 \(\.$macro) 실행",
                "\(.applicationName) \(\.$macro) 매크로",
                "\(\.$macro) 실행해줘 \(.applicationName)",
            ],
            shortTitle: "매크로 실행",
            systemImageName: "keyboard"
        )
    }
}
