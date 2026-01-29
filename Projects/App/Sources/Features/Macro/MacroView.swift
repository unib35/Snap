import ComposableArchitecture
import Shared
import SwiftUI

public struct MacroView: View {
    @Bindable var store: StoreOf<MacroFeature>

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    public init(store: StoreOf<MacroFeature>) {
        self.store = store
    }

    public var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                header
                    .padding(.horizontal)

                // Groups
                groupsSection
                    .padding(.horizontal)

                // Ungrouped Macros
                ungroupedSection
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(SnapColors.systemBackground)
        .sheet(isPresented: Binding(
            get: { store.groupEditorState != nil },
            set: { if !$0 { store.send(.dismissGroupEditor) } }
        )) {
            MacroGroupEditorView(store: store)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("매크로 패드")
                .font(.title2.weight(.bold))

            Spacer()

            if store.isEditing {
                Button {
                    store.send(.addGroupTapped)
                } label: {
                    Image(systemName: "folder.badge.plus")
                        .font(.subheadline.weight(.medium))
                }

                Button {
                    store.send(.resetToDefaults)
                } label: {
                    Text("초기화")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(SnapColors.destructive)
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

    // MARK: - Groups Section

    private var groupsSection: some View {
        ForEach(Array(store.groups.enumerated()), id: \.element.id) { index, group in
            MacroGroupSection(
                group: group,
                macros: store.macros.filter { $0.groupId == group.id },
                isEditing: store.isEditing,
                columns: columns,
                canMoveUp: index > 0,
                canMoveDown: index < store.groups.count - 1,
                onGroupTap: { store.send(.groupToggled(group)) },
                onGroupEdit: { store.send(.editGroupTapped(group)) },
                onGroupDelete: { store.send(.deleteGroup(group)) },
                onMoveUp: {
                    store.send(.groupMoved(from: IndexSet(integer: index), to: index - 1))
                },
                onMoveDown: {
                    store.send(.groupMoved(from: IndexSet(integer: index), to: index + 2))
                },
                onMacroTap: { store.send(.macroTapped($0)) },
                onMacroLongPress: { store.send(.macroLongPressed($0)) },
                onMacroDelete: { store.send(.macroDeleted($0)) },
                onAddMacro: { store.send(.addMacroTapped) }
            )
        }
    }

    // MARK: - Ungrouped Section

    private var ungroupedSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if !store.groups.isEmpty {
                Text("그룹 없음")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(SnapColors.secondaryLabel)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.ungroupedMacros) { macro in
                    MacroButton(
                        macro: macro,
                        isEditing: store.isEditing
                    ) {
                        store.send(.macroTapped(macro))
                    } onLongPress: {
                        store.send(.macroLongPressed(macro))
                    } onDelete: {
                        store.send(.macroDeleted(macro))
                    }
                    .gridCellColumns(macro.size.columnSpan)
                }

                // Add Button
                AddMacroButton {
                    store.send(.addMacroTapped)
                }
            }
        }
        .sheet(isPresented: Binding(
            get: { store.editorState != nil },
            set: { if !$0 { store.send(.dismissEditor) } }
        )) {
            MacroEditorView(store: store)
        }
        .alert("매크로 초기화", isPresented: Binding(
            get: { false },
            set: { _ in }
        )) {
            Button("취소", role: .cancel) {}
            Button("초기화", role: .destructive) {
                store.send(.confirmResetToDefaults)
            }
        } message: {
            Text("모든 매크로를 기본값으로 초기화하시겠습니까?")
        }
    }
}

// MARK: - Macro Group Section

struct MacroGroupSection: View {
    let group: MacroGroup
    let macros: [Macro]
    let isEditing: Bool
    let columns: [GridItem]
    let canMoveUp: Bool
    let canMoveDown: Bool
    let onGroupTap: () -> Void
    let onGroupEdit: () -> Void
    let onGroupDelete: () -> Void
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let onMacroTap: (Macro) -> Void
    let onMacroLongPress: (Macro) -> Void
    let onMacroDelete: (Macro) -> Void
    let onAddMacro: () -> Void

    @State private var showDeleteAlert = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Group Header
            groupHeader

            // Group Content
            if group.isExpanded {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(macros) { macro in
                        MacroButton(
                            macro: macro,
                            isEditing: isEditing
                        ) {
                            onMacroTap(macro)
                        } onLongPress: {
                            onMacroLongPress(macro)
                        } onDelete: {
                            onMacroDelete(macro)
                        }
                        .gridCellColumns(macro.size.columnSpan)
                    }
                }
                .padding(.bottom, 8)
            }
        }
        .padding()
        .background(SnapColors.secondarySystemBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .alert("그룹 삭제", isPresented: $showDeleteAlert) {
            Button("취소", role: .cancel) {}
            Button("삭제", role: .destructive) {
                onGroupDelete()
            }
        } message: {
            if macros.isEmpty {
                Text("'\(group.name)' 그룹을 삭제하시겠습니까?")
            } else {
                Text("'\(group.name)' 그룹을 삭제하시겠습니까?\n그룹 내 \(macros.count)개의 매크로는 '그룹 없음'으로 이동됩니다.")
            }
        }
    }

    private var groupHeader: some View {
        HStack {
            Button(action: onGroupTap) {
                HStack(spacing: 8) {
                    Image(systemName: group.icon)
                        .font(.headline)
                        .foregroundStyle(SnapColors.neonLime)

                    Text(group.name)
                        .font(.headline)
                        .foregroundStyle(SnapColors.label)

                    Text("\(macros.count)")
                        .font(.caption)
                        .foregroundStyle(SnapColors.secondaryLabel)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(SnapColors.tertiarySystemBackground)
                        .clipShape(Capsule())

                    Spacer()

                    Image(systemName: group.isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(SnapColors.secondaryLabel)
                }
            }
            .buttonStyle(.plain)

            if isEditing {
                // Move buttons
                HStack(spacing: 4) {
                    Button(action: onMoveUp) {
                        Image(systemName: "chevron.up")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(canMoveUp ? SnapColors.neonLime : SnapColors.tertiaryLabel)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveUp)

                    Button(action: onMoveDown) {
                        Image(systemName: "chevron.down")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(canMoveDown ? SnapColors.neonLime : SnapColors.tertiaryLabel)
                    }
                    .buttonStyle(.plain)
                    .disabled(!canMoveDown)
                }
                .padding(.horizontal, 4)

                Button(action: onGroupEdit) {
                    Image(systemName: "pencil")
                        .font(.caption)
                        .foregroundStyle(SnapColors.neonLime)
                }
                .buttonStyle(.plain)

                Button {
                    showDeleteAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.caption)
                        .foregroundStyle(SnapColors.destructive)
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Macro Group Editor View

struct MacroGroupEditorView: View {
    @Bindable var store: StoreOf<MacroFeature>
    @Environment(\.dismiss) private var dismiss

    private var group: MacroGroup? {
        store.groupEditorState?.group
    }

    private var isNew: Bool {
        store.groupEditorState?.isNew ?? true
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("그룹 정보") {
                    TextField("그룹 이름", text: Binding(
                        get: { group?.name ?? "" },
                        set: { store.send(.updateGroupName($0)) }
                    ))

                    HStack {
                        Text("아이콘")
                        Spacer()
                        iconPicker
                    }
                }
            }
            .navigationTitle(isNew ? "새 그룹" : "그룹 편집")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("취소") {
                        store.send(.dismissGroupEditor)
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("저장") {
                        if let group = group {
                            store.send(.saveGroup(group))
                        }
                    }
                    .disabled(group?.name.isEmpty ?? true)
                }
            }
        }
        .presentationDetents([.medium])
    }

    private var iconPicker: some View {
        let icons = [
            "folder.fill", "star.fill", "heart.fill", "bookmark.fill",
            "tag.fill", "flag.fill", "bolt.fill", "gear",
            "command", "keyboard", "display", "desktopcomputer",
        ]

        return Menu {
            ForEach(icons, id: \.self) { icon in
                Button {
                    store.send(.updateGroupIcon(icon))
                } label: {
                    Label(icon, systemImage: icon)
                }
            }
        } label: {
            Image(systemName: group?.icon ?? "folder.fill")
                .font(.title3)
                .foregroundStyle(SnapColors.neonLime)
                .frame(width: 32, height: 32)
                .background(SnapColors.tertiarySystemBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        }
    }
}

// MARK: - Add Macro Button

struct AddMacroButton: View {
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(SnapColors.secondaryLabel)

                Text("추가")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(SnapColors.tertiaryLabel)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(SnapColors.tertiarySystemBackground)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(
                                SnapColors.separator,
                                style: StrokeStyle(lineWidth: 2, dash: [8, 4])
                            )
                    )
            )
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("매크로 추가")
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

// MARK: - Macro Button

struct MacroButton: View {
    let macro: Macro
    let isEditing: Bool
    let onTap: () -> Void
    let onLongPress: () -> Void
    let onDelete: () -> Void

    @State private var isPressed = false
    @State private var isWiggling = false

    var body: some View {
        Button {
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
            LongPressGesture(minimumDuration: 0.5)
                .onEnded { _ in
                    onLongPress()
                }
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
        .accessibilityLabel("\(macro.name) 매크로")
    }

    private var content: some View {
        VStack(spacing: 8) {
            Image(systemName: macro.icon)
                .font(.system(size: macro.size == .large ? 32 : 24))
                .foregroundStyle(.white)

            Text(macro.name)
                .font(macro.size == .small ? .caption2 : .caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: macro.size.height)
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

    private var deleteButton: some View {
        Button {
            onDelete()
        } label: {
            Image(systemName: "xmark.circle.fill")
                .font(.title3)
                .foregroundStyle(.white, SnapColors.destructive)
        }
        .offset(x: 8, y: -8)
    }
}

// MARK: - Macro Size Extension

extension MacroSize {
    var columnSpan: Int {
        switch self {
        case .small: return 1
        case .medium: return 2
        case .large: return 2
        }
    }

    var height: CGFloat {
        switch self {
        case .small: return 80
        case .medium: return 80
        case .large: return 172
        }
    }
}

// MARK: - Macro Color Extension

extension MacroColor {
    var color: Color {
        switch self {
        case .blue: return .blue
        case .purple: return .purple
        case .pink: return .pink
        case .red: return .red
        case .orange: return .orange
        case .yellow: return .yellow
        case .green: return .green
        case .teal: return .teal
        case .gray: return .gray
        }
    }

    var gradient: LinearGradient {
        LinearGradient(
            colors: [color, color.opacity(0.8)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }
}

// MARK: - Macro Pad Section (for embedding in ProductivityView)

public struct MacroPadSection: View {
    @Bindable var store: StoreOf<MacroFeature>
    @State private var showResetAlert = false

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    public init(store: StoreOf<MacroFeature>) {
        self.store = store
    }

    public var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Text("매크로 패드")
                    .font(.headline)

                Spacer()

                if store.isEditing {
                    Button {
                        store.send(.addGroupTapped)
                    } label: {
                        Image(systemName: "folder.badge.plus")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)

                    Button {
                        showResetAlert = true
                    } label: {
                        Text("초기화")
                            .font(.caption)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .tint(SnapColors.destructive)
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

            // Groups
            ForEach(Array(store.groups.enumerated()), id: \.element.id) { index, group in
                MacroGroupSection(
                    group: group,
                    macros: store.macros.filter { $0.groupId == group.id },
                    isEditing: store.isEditing,
                    columns: columns,
                    canMoveUp: index > 0,
                    canMoveDown: index < store.groups.count - 1,
                    onGroupTap: { store.send(.groupToggled(group)) },
                    onGroupEdit: { store.send(.editGroupTapped(group)) },
                    onGroupDelete: { store.send(.deleteGroup(group)) },
                    onMoveUp: {
                        store.send(.groupMoved(from: IndexSet(integer: index), to: index - 1))
                    },
                    onMoveDown: {
                        store.send(.groupMoved(from: IndexSet(integer: index), to: index + 2))
                    },
                    onMacroTap: { store.send(.macroTapped($0)) },
                    onMacroLongPress: { store.send(.macroLongPressed($0)) },
                    onMacroDelete: { store.send(.macroDeleted($0)) },
                    onAddMacro: { store.send(.addMacroTapped) }
                )
            }

            // Ungrouped Macros
            if !store.groups.isEmpty {
                Text("그룹 없음")
                    .font(.caption)
                    .foregroundStyle(SnapColors.secondaryLabel)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.ungroupedMacros) { macro in
                    MacroButton(
                        macro: macro,
                        isEditing: store.isEditing
                    ) {
                        store.send(.macroTapped(macro))
                    } onLongPress: {
                        store.send(.macroLongPressed(macro))
                    } onDelete: {
                        store.send(.macroDeleted(macro))
                    }
                    .gridCellColumns(macro.size.columnSpan)
                }

                // Add Button
                AddMacroButton {
                    store.send(.addMacroTapped)
                }
            }
        }
        .padding()
        .background(SnapColors.secondarySystemBackground.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .sheet(isPresented: Binding(
            get: { store.editorState != nil },
            set: { if !$0 { store.send(.dismissEditor) } }
        )) {
            MacroEditorView(store: store)
        }
        .sheet(isPresented: Binding(
            get: { store.groupEditorState != nil },
            set: { if !$0 { store.send(.dismissGroupEditor) } }
        )) {
            MacroGroupEditorView(store: store)
        }
        .alert("매크로 초기화", isPresented: $showResetAlert) {
            Button("취소", role: .cancel) {}
            Button("초기화", role: .destructive) {
                store.send(.confirmResetToDefaults)
            }
        } message: {
            Text("모든 매크로를 기본값으로 초기화하시겠습니까?")
        }
    }
}

#Preview {
    MacroView(
        store: Store(initialState: MacroFeature.State()) {
            MacroFeature()
        }
    )
}

#Preview("MacroPadSection") {
    MacroPadSection(
        store: Store(initialState: MacroFeature.State()) {
            MacroFeature()
        }
    )
    .padding()
}
