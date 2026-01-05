import ComposableArchitecture
import SwiftUI
import UIKit

public struct QuickLaunchView: View {
    @Bindable var store: StoreOf<QuickLaunchFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(store: StoreOf<QuickLaunchFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                header
                    .padding(.horizontal)

                itemsGrid
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
        .sheet(isPresented: Binding(
            get: { store.editorState != nil },
            set: { if !$0 { store.send(.dismissEditor) } }
        )) {
            QuickLaunchEditorView(store: store)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("퀵 런치")
                .font(.title2.weight(.bold))

            Spacer()

            if store.isEditing {
                Button {
                    store.send(.resetToDefaults)
                } label: {
                    Text("초기화")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.red)
                }
            }

            Button {
                store.send(.editModeToggled)
            } label: {
                Text(store.isEditing ? "완료" : "편집")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    // MARK: - Items Grid

    private var itemsGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.items) { item in
                QuickLaunchButton(
                    item: item,
                    isEditing: store.isEditing
                ) {
                    store.send(.itemTapped(item))
                } onDelete: {
                    store.send(.itemDeleted(item))
                }
            }

            // Add Button
            AddQuickLaunchButton {
                store.send(.addItemTapped)
            }
        }
    }
}

// MARK: - Quick Launch Button

struct QuickLaunchButton: View {
    let item: QuickLaunchFeature.QuickLaunchItem
    let isEditing: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var isWiggling = false

    var body: some View {
        Button {
            triggerHaptic()
            onTap()
        } label: {
            content
        }
        .buttonStyle(.plain)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .rotationEffect(.degrees(isEditing && isWiggling ? 1.5 : 0))
        .animation(
            isEditing
                ? .easeInOut(duration: 0.1).repeatForever(autoreverses: true)
                : .default,
            value: isWiggling
        )
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.spring(response: 0.2)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
        )
        .overlay(alignment: .topTrailing) {
            if isEditing {
                deleteButton
            }
        }
        .onChange(of: isEditing) { _, editing in
            isWiggling = editing
        }
        .accessibilityLabel("\(item.name) 바로가기")
    }

    private var content: some View {
        VStack(spacing: 8) {
            Image(systemName: item.icon)
                .font(.system(size: 24))
                .foregroundStyle(.white)

            Text(item.name)
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 80)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(item.color.color.gradient)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(.white.opacity(0.2), lineWidth: 1)
        )
        .shadow(color: item.color.color.opacity(0.3), radius: 8, y: 4)
    }

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, .red)
        }
        .offset(x: 8, y: -8)
    }

    private func triggerHaptic() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
}

// MARK: - Add Quick Launch Button

struct AddQuickLaunchButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(Color(.secondaryLabel))

                Text("추가")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color(.tertiaryLabel))
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.tertiarySystemBackground))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                Color(.separator),
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("바로가기 추가")
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.spring(response: 0.2)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.2)) {
                        isPressed = false
                    }
                }
        )
    }
}

// MARK: - Quick Launch Editor View

struct QuickLaunchEditorView: View {
    @Bindable var store: StoreOf<QuickLaunchFeature>
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                // Name
                Section("이름") {
                    TextField("바로가기 이름", text: Binding(
                        get: { store.editorState?.item.name ?? "" },
                        set: { store.send(.updateItemName($0)) }
                    ))
                }

                // URL
                Section("URL") {
                    TextField("https://example.com", text: Binding(
                        get: { store.editorState?.item.url ?? "" },
                        set: { store.send(.updateItemURL($0)) }
                    ))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .autocorrectionDisabled()
                }

                // Icon
                Section("아이콘") {
                    QuickLaunchIconPicker(
                        selectedIcon: store.editorState?.item.icon ?? "link"
                    ) { icon in
                        store.send(.updateItemIcon(icon))
                    }
                }

                // Color
                Section("색상") {
                    QuickLaunchColorPicker(
                        selectedColor: store.editorState?.item.color ?? .blue
                    ) { color in
                        store.send(.updateItemColor(color))
                    }
                }
            }
            .navigationTitle(store.editorState?.isNew == true ? "바로가기 추가" : "바로가기 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        store.send(.dismissEditor)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        if let item = store.editorState?.item {
                            store.send(.saveItem(item))
                        }
                    }
                    .disabled(store.editorState?.item.name.isEmpty == true ||
                              store.editorState?.item.url.isEmpty == true)
                }
            }
        }
    }
}

// MARK: - Icon Picker

struct QuickLaunchIconPicker: View {
    let selectedIcon: String
    let onSelect: (String) -> Void

    private let icons = [
        "link", "globe", "safari.fill", "play.tv.fill",
        "play.rectangle.fill", "music.note", "film.fill", "gamecontroller.fill",
        "cart.fill", "bag.fill", "creditcard.fill", "house.fill",
        "building.2.fill", "briefcase.fill", "book.fill", "newspaper.fill",
        "envelope.fill", "bubble.left.fill", "phone.fill", "video.fill",
        "camera.fill", "photo.fill", "map.fill", "location.fill",
        "cloud.fill", "doc.fill", "folder.fill", "tray.fill",
        "chevron.left.forwardslash.chevron.right", "terminal.fill", "cpu.fill", "memorychip.fill",
        "bubble.left.and.bubble.right.fill", "person.fill", "person.2.fill", "star.fill"
    ]

    private let columns = [
        GridItem(.adaptive(minimum: 44), spacing: 8)
    ]

    var body: some View {
        LazyVGrid(columns: columns, spacing: 8) {
            ForEach(icons, id: \.self) { icon in
                Button {
                    onSelect(icon)
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 20))
                        .frame(width: 44, height: 44)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedIcon == icon
                                      ? Color.accentColor.opacity(0.2)
                                      : Color(.tertiarySystemBackground))
                        )
                        .foregroundStyle(selectedIcon == icon ? Color.accentColor : .primary)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .strokeBorder(
                                    selectedIcon == icon ? Color.accentColor : Color.clear,
                                    lineWidth: 2
                                )
                        )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Color Picker

struct QuickLaunchColorPicker: View {
    let selectedColor: QuickLaunchFeature.QuickLaunchColor
    let onSelect: (QuickLaunchFeature.QuickLaunchColor) -> Void

    var body: some View {
        HStack(spacing: 12) {
            ForEach(QuickLaunchFeature.QuickLaunchColor.allCases, id: \.self) { color in
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
                        .overlay(
                            Circle()
                                .strokeBorder(Color(.separator), lineWidth: 1)
                        )
                        .shadow(color: color.color.opacity(0.3), radius: 4, y: 2)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Quick Launch Section (for ProductivityView)

public struct QuickLaunchSection: View {
    @Bindable var store: StoreOf<QuickLaunchFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    public init(store: StoreOf<QuickLaunchFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "link")
                    .foregroundStyle(.blue)
                Text("퀵 런치")
                    .font(.headline)

                Spacer()

                if store.isEditing {
                    Button {
                        store.send(.resetToDefaults)
                    } label: {
                        Text("초기화")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(.red)
                }

                Button {
                    store.send(.editModeToggled)
                } label: {
                    Text(store.isEditing ? "완료" : "편집")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Items Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.items) { item in
                    QuickLaunchButton(
                        item: item,
                        isEditing: store.isEditing
                    ) {
                        store.send(.itemTapped(item))
                    } onDelete: {
                        store.send(.itemDeleted(item))
                    }
                }

                AddQuickLaunchButton {
                    store.send(.addItemTapped)
                }
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: Binding(
            get: { store.editorState != nil },
            set: { if !$0 { store.send(.dismissEditor) } }
        )) {
            QuickLaunchEditorView(store: store)
        }
    }
}

// MARK: - Preview

#Preview {
    QuickLaunchView(
        store: Store(initialState: QuickLaunchFeature.State()) {
            QuickLaunchFeature()
        }
    )
}

#Preview("Section") {
    QuickLaunchSection(
        store: Store(initialState: QuickLaunchFeature.State()) {
            QuickLaunchFeature()
        }
    )
    .padding()
}
