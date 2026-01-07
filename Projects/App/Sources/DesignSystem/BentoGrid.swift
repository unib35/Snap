import SwiftUI

// MARK: - Bento Grid System

/// Bento Grid 컨테이너
public struct BentoGrid<Content: View>: View {
    let columns: Int
    let spacing: CGFloat
    let content: Content

    public init(
        columns: Int = 2,
        spacing: CGFloat = SnapSpacing.md,
        @ViewBuilder content: () -> Content
    ) {
        self.columns = columns
        self.spacing = spacing
        self.content = content()
    }

    public var body: some View {
        LazyVGrid(
            columns: Array(repeating: GridItem(.flexible(), spacing: spacing), count: columns),
            spacing: spacing
        ) {
            content
        }
        .padding(spacing)
    }
}

// MARK: - Bento Cell

/// Bento Grid 셀 (카드)
public struct BentoCell<Content: View>: View {
    let span: Int
    let height: BentoCellHeight
    let content: Content

    public enum BentoCellHeight {
        case small      // 100pt
        case medium     // 140pt
        case large      // 200pt
        case extraLarge // 280pt
        case flexible   // 콘텐츠에 맞춤

        var value: CGFloat? {
            switch self {
            case .small: 100
            case .medium: 140
            case .large: 200
            case .extraLarge: 280
            case .flexible: nil
            }
        }
    }

    public init(
        span: Int = 1,
        height: BentoCellHeight = .medium,
        @ViewBuilder content: () -> Content
    ) {
        self.span = span
        self.height = height
        self.content = content()
    }

    public var body: some View {
        content
            .frame(maxWidth: .infinity)
            .frame(height: height.value)
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                    .stroke(SnapColors.border, lineWidth: 0.5)
            )
    }
}

// MARK: - Bento Card Styles

/// 기본 Bento 카드
public struct BentoCard<Content: View>: View {
    let title: String
    let icon: String
    let accentColor: Color
    let content: Content

    public init(
        title: String,
        icon: String,
        accentColor: Color = SnapColors.neonLime,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.content = content()
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: SnapSpacing.md) {
            HStack(spacing: SnapSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(accentColor)

                Text(title)
                    .font(SnapTypography.labelLarge)
                    .foregroundStyle(SnapColors.textPrimary)

                Spacer()
            }

            content
        }
        .padding(SnapSpacing.lg)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
        .overlay(
            RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                .stroke(SnapColors.border, lineWidth: 0.5)
        )
    }
}

/// 아이콘 버튼 Bento 카드
public struct BentoIconButton: View {
    let title: String
    let icon: String
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    public init(
        title: String,
        icon: String,
        accentColor: Color = SnapColors.neonLime,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.action = action
    }

    public var body: some View {
        Button(action: action) {
            VStack(spacing: SnapSpacing.md) {
                ZStack {
                    Circle()
                        .fill(accentColor.opacity(0.15))
                        .frame(width: 56, height: 56)

                    Image(systemName: icon)
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(accentColor)
                }

                Text(title)
                    .font(SnapTypography.labelMedium)
                    .foregroundStyle(SnapColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.lg)
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.lg))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.lg)
                    .stroke(isPressed ? accentColor : SnapColors.border, lineWidth: isPressed ? 1 : 0.5)
            )
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

/// 상태 표시 Bento 카드
public struct BentoStatusCard: View {
    let title: String
    let value: String
    let icon: String
    let status: Status
    let action: (() -> Void)?

    public enum Status {
        case active
        case inactive
        case warning
        case error

        var color: Color {
            switch self {
            case .active: SnapColors.neonLime
            case .inactive: SnapColors.textTertiary
            case .warning: SnapColors.neonOrange
            case .error: SnapColors.neonRed
            }
        }
    }

    public init(
        title: String,
        value: String,
        icon: String,
        status: Status = .inactive,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.value = value
        self.icon = icon
        self.status = status
        self.action = action
    }

    public var body: some View {
        Button {
            action?()
        } label: {
            HStack(spacing: SnapSpacing.md) {
                ZStack {
                    Circle()
                        .fill(status.color.opacity(0.15))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(status.color)
                }

                VStack(alignment: .leading, spacing: SnapSpacing.xxs) {
                    Text(title)
                        .font(SnapTypography.labelSmall)
                        .foregroundStyle(SnapColors.textTertiary)

                    Text(value)
                        .font(SnapTypography.headlineSmall)
                        .foregroundStyle(SnapColors.textPrimary)
                }

                Spacer()

                if action != nil {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(SnapColors.textTertiary)
                }
            }
            .padding(SnapSpacing.md)
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                    .stroke(SnapColors.border, lineWidth: 0.5)
            )
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }
}

// MARK: - Section Header

/// 섹션 헤더
public struct BentoSectionHeader: View {
    let title: String
    let icon: String?
    let action: (() -> Void)?
    let actionLabel: String?

    public init(
        _ title: String,
        icon: String? = nil,
        action: (() -> Void)? = nil,
        actionLabel: String? = nil
    ) {
        self.title = title
        self.icon = icon
        self.action = action
        self.actionLabel = actionLabel
    }

    public var body: some View {
        HStack {
            if let icon {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(SnapColors.neonLime)
            }

            Text(title)
                .font(SnapTypography.headlineSmall)
                .foregroundStyle(SnapColors.textPrimary)

            Spacer()

            if let action, let actionLabel {
                Button(action: action) {
                    Text(actionLabel)
                        .font(SnapTypography.labelMedium)
                        .foregroundStyle(SnapColors.cyberBlue)
                }
            }
        }
        .padding(.horizontal, SnapSpacing.lg)
        .padding(.vertical, SnapSpacing.sm)
    }
}
