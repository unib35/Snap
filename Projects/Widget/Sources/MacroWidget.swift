import SwiftUI
import WidgetKit

// MARK: - Macro Widget

struct MacroWidget: Widget {
    let kind: String = "MacroWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: MacroProvider()) { entry in
            MacroWidgetView(entry: entry)
                .containerBackground(.fill.tertiary, for: .widget)
        }
        .configurationDisplayName("매크로")
        .description("자주 사용하는 매크로를 빠르게 실행합니다.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Macro Item

struct WidgetMacroItem: Identifiable, Codable {
    let id: UUID
    let name: String
    let icon: String
    let colorName: String

    var color: Color {
        switch colorName {
        case "blue": return .blue
        case "purple": return .purple
        case "pink": return .pink
        case "red": return .red
        case "orange": return .orange
        case "yellow": return .yellow
        case "green": return .green
        case "teal": return .teal
        case "gray": return .gray
        default: return .blue
        }
    }
}

// MARK: - Entry

struct MacroEntry: TimelineEntry {
    let date: Date
    let macros: [WidgetMacroItem]
}

// MARK: - Provider

struct MacroProvider: TimelineProvider {
    func placeholder(in context: Context) -> MacroEntry {
        MacroEntry(date: Date(), macros: defaultMacros)
    }

    func getSnapshot(in context: Context, completion: @escaping (MacroEntry) -> Void) {
        let macros = WidgetDataManager.loadMacros()
        let entry = MacroEntry(date: Date(), macros: macros.isEmpty ? defaultMacros : macros)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<MacroEntry>) -> Void) {
        let macros = WidgetDataManager.loadMacros()
        let entry = MacroEntry(date: Date(), macros: macros.isEmpty ? defaultMacros : macros)

        // Update every 15 minutes
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date()) ?? Date()
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private var defaultMacros: [WidgetMacroItem] {
        [
            WidgetMacroItem(id: UUID(), name: "복사", icon: "doc.on.doc", colorName: "blue"),
            WidgetMacroItem(id: UUID(), name: "붙여넣기", icon: "doc.on.clipboard", colorName: "green"),
            WidgetMacroItem(id: UUID(), name: "실행취소", icon: "arrow.uturn.backward", colorName: "orange"),
            WidgetMacroItem(id: UUID(), name: "저장", icon: "square.and.arrow.down", colorName: "purple")
        ]
    }
}

// MARK: - Widget View

struct MacroWidgetView: View {
    var entry: MacroEntry

    @Environment(\.widgetFamily) var family

    var body: some View {
        switch family {
        case .systemSmall:
            smallView
        case .systemMedium:
            mediumView
        default:
            smallView
        }
    }

    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "keyboard")
                    .foregroundStyle(.secondary)
                Text("매크로")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(entry.macros.prefix(4)) { macro in
                    if let url = URL(string: "snap://macro/\(macro.id.uuidString)") {
                        Link(destination: url) {
                            MacroButtonSmall(macro: macro)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var mediumView: some View {
        VStack(spacing: 8) {
            HStack {
                Image(systemName: "keyboard")
                    .foregroundStyle(.secondary)
                Text("매크로")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                Spacer()

                if let moreURL = URL(string: "snap://macros") {
                    Link(destination: moreURL) {
                        Text("더보기")
                            .font(.caption)
                            .foregroundStyle(Color.accentColor)
                    }
                }
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8),
                GridItem(.flexible(), spacing: 8)
            ], spacing: 8) {
                ForEach(entry.macros.prefix(8)) { macro in
                    if let url = URL(string: "snap://macro/\(macro.id.uuidString)") {
                        Link(destination: url) {
                            MacroButtonMedium(macro: macro)
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

// MARK: - Macro Button Small

struct MacroButtonSmall: View {
    let macro: WidgetMacroItem

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: macro.icon)
                .font(.system(size: 18))
                .foregroundStyle(.white)

            Text(macro.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(macro.color.gradient)
        )
    }
}

// MARK: - Macro Button Medium

struct MacroButtonMedium: View {
    let macro: WidgetMacroItem

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: macro.icon)
                .font(.system(size: 20))
                .foregroundStyle(.white)

            Text(macro.name)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.white.opacity(0.9))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 50)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(macro.color.gradient)
        )
    }
}

// MARK: - Preview

#Preview(as: .systemSmall) {
    MacroWidget()
} timeline: {
    MacroEntry(date: .now, macros: [
        WidgetMacroItem(id: UUID(), name: "복사", icon: "doc.on.doc", colorName: "blue"),
        WidgetMacroItem(id: UUID(), name: "붙여넣기", icon: "doc.on.clipboard", colorName: "green"),
        WidgetMacroItem(id: UUID(), name: "실행취소", icon: "arrow.uturn.backward", colorName: "orange"),
        WidgetMacroItem(id: UUID(), name: "저장", icon: "square.and.arrow.down", colorName: "purple")
    ])
}

#Preview(as: .systemMedium) {
    MacroWidget()
} timeline: {
    MacroEntry(date: .now, macros: [
        WidgetMacroItem(id: UUID(), name: "복사", icon: "doc.on.doc", colorName: "blue"),
        WidgetMacroItem(id: UUID(), name: "붙여넣기", icon: "doc.on.clipboard", colorName: "green"),
        WidgetMacroItem(id: UUID(), name: "실행취소", icon: "arrow.uturn.backward", colorName: "orange"),
        WidgetMacroItem(id: UUID(), name: "저장", icon: "square.and.arrow.down", colorName: "purple"),
        WidgetMacroItem(id: UUID(), name: "잘라내기", icon: "scissors", colorName: "red"),
        WidgetMacroItem(id: UUID(), name: "스크린샷", icon: "camera.viewfinder", colorName: "teal"),
        WidgetMacroItem(id: UUID(), name: "새로고침", icon: "arrow.clockwise", colorName: "pink"),
        WidgetMacroItem(id: UUID(), name: "전체선택", icon: "selection.pin.in.out", colorName: "gray")
    ])
}
