import ComposableArchitecture
import Foundation
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

        public enum ItemType: String, Codable, Sendable {
            case url
            case app
        }

        public init(
            id: UUID = UUID(),
            name: String,
            icon: String,
            color: QuickLaunchColor,
            type: ItemType,
            url: String
        ) {
            self.id = id
            self.name = name
            self.icon = icon
            self.color = color
            self.type = type
            self.url = url
        }

        // Default presets
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

                return .run { [connectionClient] _ in
                    await connectionClient.sendOpenURL(item.url)
                }

            case .itemDeleted(let item):
                state.items.removeAll { $0.id == item.id }
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

            case .resetToDefaults:
                state.items = QuickLaunchItem.defaults
                state.saveItems()
                return .none
            }
        }
    }
}
