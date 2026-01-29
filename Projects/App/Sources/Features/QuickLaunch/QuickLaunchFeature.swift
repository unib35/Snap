import ComposableArchitecture
import Foundation
import Shared
import SwiftUI

@Reducer
public struct QuickLaunchFeature {
    // MARK: - Quick Launch Item

    public struct QuickLaunchItem: Codable, Identifiable, Equatable, Sendable {
        public var id: UUID
        public var name: String
        public var icon: String
        public var color: QuickLaunchColor
        public var type: ItemType
        public var url: String
        // App-specific properties
        public var bundleID: String?
        public var pid: UInt32?

        public enum ItemType: String, Codable, Sendable {
            case url
            case app
            case system
        }

        public init(
            id: UUID = UUID(),
            name: String,
            icon: String,
            color: QuickLaunchColor,
            type: ItemType,
            url: String,
            bundleID: String? = nil,
            pid: UInt32? = nil
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.color = color
            self.type = type
            self.url = url
            self.bundleID = bundleID
            self.pid = pid
        }

        // Default URL presets
        public static let defaults: [QuickLaunchItem] = [
            QuickLaunchItem(
                name: "Netflix",
                icon: "play.tv.fill",
                color: .red,
                type: .url,
                url: "https://www.netflix.com"
            ),
            QuickLaunchItem(
                name: "YouTube",
                icon: "play.rectangle.fill",
                color: .red,
                type: .url,
                url: "https://www.youtube.com"
            ),
            QuickLaunchItem(
                name: "Spotify",
                icon: "music.note",
                color: .green,
                type: .url,
                url: "https://open.spotify.com"
            ),
            QuickLaunchItem(
                name: "GitHub",
                icon: "chevron.left.forwardslash.chevron.right",
                color: .gray,
                type: .url,
                url: "https://github.com"
            ),
            QuickLaunchItem(
                name: "ChatGPT",
                icon: "bubble.left.and.bubble.right.fill",
                color: .teal,
                type: .url,
                url: "https://chat.openai.com"
            ),
            QuickLaunchItem(
                name: "Twitter",
                icon: "bubble.left.fill",
                color: .blue,
                type: .url,
                url: "https://twitter.com"
            )
        ]

        // System command presets
        public static let systemCommands: [QuickLaunchItem] = [
            QuickLaunchItem(
                name: "잠자기",
                icon: "moon.fill",
                color: .purple,
                type: .system,
                url: "system://sleep"
            ),
            QuickLaunchItem(
                name: "화면 잠금",
                icon: "lock.fill",
                color: .blue,
                type: .system,
                url: "system://lock"
            ),
            QuickLaunchItem(
                name: "로그아웃",
                icon: "rectangle.portrait.and.arrow.right",
                color: .orange,
                type: .system,
                url: "system://logout"
            ),
            QuickLaunchItem(
                name: "재시작",
                icon: "arrow.clockwise.circle.fill",
                color: .yellow,
                type: .system,
                url: "system://restart"
            ),
            QuickLaunchItem(
                name: "시스템 종료",
                icon: "power",
                color: .red,
                type: .system,
                url: "system://shutdown"
            )
        ]

        /// URL에서 시스템 명령 파싱
        public var systemCommand: SystemCommand.Command? {
            guard type == .system else { return nil }
            switch url {
            case "system://sleep": return .sleep
            case "system://lock": return .lock
            case "system://logout": return .logout
            case "system://restart": return .restart
            case "system://shutdown": return .shutdown
            default: return nil
            }
        }

        /// 위험한 시스템 명령 여부 (확인 필요)
        public var isDangerousCommand: Bool {
            guard let command = systemCommand else { return false }
            switch command {
            case .logout, .restart, .shutdown:
                return true
            case .sleep, .lock:
                return false
            }
        }
    }

    public enum QuickLaunchColor: String, Codable, CaseIterable, Sendable {
        case red, orange, yellow, green, teal, blue, purple, pink, gray

        public var color: Color {
            switch self {
            case .red: return .red
            case .orange: return .orange
            case .yellow: return .yellow
            case .green: return .green
            case .teal: return .teal
            case .blue: return .blue
            case .purple: return .purple
            case .pink: return .pink
            case .gray: return .gray
            }
        }
    }

    // MARK: - State

    @ObservableState
    public struct State: Equatable {
        public var items: [QuickLaunchItem] = []
        public var isEditing: Bool = false
        public var editorState: EditorState?
        public var confirmationItem: QuickLaunchItem?

        public init() {
            self.items = Self.loadItems()
        }

        // MARK: - Persistence

        private static let itemsKey = "snap.quickLaunchItems"

        static func loadItems() -> [QuickLaunchItem] {
            guard let data = UserDefaults.standard.data(forKey: itemsKey),
                  let items = try? JSONDecoder().decode([QuickLaunchItem].self, from: data) else {
                return QuickLaunchItem.defaults
            }
            return items
        }

        mutating func saveItems() {
            if let data = try? JSONEncoder().encode(items) {
                UserDefaults.standard.set(data, forKey: Self.itemsKey)
            }
        }
    }

    // MARK: - Editor State

    public struct EditorState: Equatable {
        public var item: QuickLaunchItem
        public var isNew: Bool

        public init(item: QuickLaunchItem? = nil) {
            if let item = item {
                self.item = item
                self.isNew = false
            } else {
                self.item = QuickLaunchItem(
                    name: "",
                    icon: "link",
                    color: .blue,
                    type: .url,
                    url: ""
                )
                self.isNew = true
            }
        }
    }

    // MARK: - Action

    public enum Action: Equatable, Sendable {
        // Item actions
        case itemTapped(QuickLaunchItem)
        case itemDeleted(QuickLaunchItem)
        case itemMoved(from: IndexSet, to: Int)

        // Edit mode
        case editModeToggled

        // Editor
        case addItemTapped
        case editItemTapped(QuickLaunchItem)
        case dismissEditor
        case saveItem(QuickLaunchItem)

        // Editor field updates
        case updateItemName(String)
        case updateItemIcon(String)
        case updateItemColor(QuickLaunchColor)
        case updateItemType(QuickLaunchItem.ItemType)
        case updateItemURL(String)

        // System command confirmation
        case showConfirmation(QuickLaunchItem)
        case confirmSystemCommand
        case dismissConfirmation

        // Reset
        case resetToDefaults
    }

    // MARK: - Dependencies

    @Dependency(\.connectionClient) var connectionClient

    public init() {}

    // MARK: - Body

    public var body: some ReducerOf<Self> {
        Reduce { state, action in
            switch action {
            case .itemTapped(let item):
                guard !state.isEditing else {
                    return .send(.editItemTapped(item))
                }

                switch item.type {
                case .url:
                    return .run { [connectionClient] _ in
                        await connectionClient.sendOpenURL(item.url)
                    }

                case .app:
                    guard let bundleID = item.bundleID, let pid = item.pid else {
                        return .none
                    }
                    return .run { [connectionClient] _ in
                        await connectionClient.sendAppFocus(bundleID, pid)
                    }

                case .system:
                    // 위험한 명령은 확인 필요
                    if item.isDangerousCommand {
                        return .send(.showConfirmation(item))
                    }
                    guard let command = item.systemCommand else { return .none }
                    return .run { [connectionClient] _ in
                        await connectionClient.sendSystemCommand(command)
                    }
                }

            case .itemDeleted(let item):
                state.items.removeAll { $0.id == item.id }
                state.saveItems()
                return .none

            case .itemMoved(let source, let destination):
                state.items.move(fromOffsets: source, toOffset: destination)
                state.saveItems()
                return .none

            case .editModeToggled:
                state.isEditing.toggle()
                return .none

            case .addItemTapped:
                state.editorState = EditorState()
                return .none

            case .editItemTapped(let item):
                state.editorState = EditorState(item: item)
                return .none

            case .dismissEditor:
                state.editorState = nil
                return .none

            case .saveItem(let item):
                if let index = state.items.firstIndex(where: { $0.id == item.id }) {
                    state.items[index] = item
                } else {
                    state.items.append(item)
                }
                state.editorState = nil
                state.saveItems()
                return .none

            case .updateItemName(let name):
                state.editorState?.item.name = name
                return .none

            case .updateItemIcon(let icon):
                state.editorState?.item.icon = icon
                return .none

            case .updateItemColor(let color):
                state.editorState?.item.color = color
                return .none

            case .updateItemType(let type):
                state.editorState?.item.type = type
                return .none

            case .updateItemURL(let url):
                state.editorState?.item.url = url
                return .none

            case .showConfirmation(let item):
                state.confirmationItem = item
                return .none

            case .confirmSystemCommand:
                guard let item = state.confirmationItem,
                      let command = item.systemCommand else {
                    state.confirmationItem = nil
                    return .none
                }
                state.confirmationItem = nil
                return .run { [connectionClient] _ in
                    await connectionClient.sendSystemCommand(command)
                }

            case .dismissConfirmation:
                state.confirmationItem = nil
                return .none

            case .resetToDefaults:
                state.items = QuickLaunchItem.defaults
                state.saveItems()
                return .none
            }
        }
    }
}
