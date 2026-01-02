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

                // Bento Grid
                bentoGrid
                    .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .background(Color(.systemBackground))
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Text("매크로 패드")
                .font(.title2.weight(.bold))

            Spacer()

            Button {
                store.send(.editModeToggled)
            } label: {
                Text(store.isEditing ? "완료" : "편집")
                    .font(.subheadline.weight(.medium))
            }
        }
    }

    // MARK: - Bento Grid

    private var bentoGrid: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(store.macros) { macro in
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
        }
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
                .foregroundStyle(.white, .red)
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

                Button {
                    store.send(.editModeToggled)
                } label: {
                    Text(store.isEditing ? "완료" : "편집")
                        .font(.caption)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }

            // Bento Grid
            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(store.macros) { macro in
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
            }
        }
        .padding()
        .background(Color(.secondarySystemBackground).opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 16))
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
