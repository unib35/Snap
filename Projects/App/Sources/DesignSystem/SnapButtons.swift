import SwiftUI

// MARK: - Primary Button

/// 기본 버튼 (Neon Accent)
public struct SnapPrimaryButton: View {
    let title: String
    let icon: String?
    let isLoading: Bool
    let action: () -> Void

    @State private var isPressed = false

    public init(
        _ title: String,
        icon: String? = nil,
        isLoading: Bool = false,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.isLoading = isLoading
        self.action = action
    }

    public var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            HStack(spacing: SnapSpacing.sm) {
                if isLoading {
                    ProgressView()
                        .tint(SnapColors.background)
                } else {
                    if let icon {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    Text(title)
                        .font(SnapTypography.labelLarge)
                }
            }
            .foregroundStyle(SnapColors.background)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.md)
            .background(SnapColors.neonLime)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
            .scaleEffect(isPressed ? 0.96 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .disabled(isLoading)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Secondary Button

/// 보조 버튼 (테두리)
public struct SnapSecondaryButton: View {
    let title: String
    let icon: String?
    let accentColor: Color
    let action: () -> Void

    @State private var isPressed = false

    public init(
        _ title: String,
        icon: String? = nil,
        accentColor: Color = SnapColors.neonLime,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.action = action
    }

    public var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            HStack(spacing: SnapSpacing.sm) {
                if let icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                }
                Text(title)
                    .font(SnapTypography.labelLarge)
            }
            .foregroundStyle(accentColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, SnapSpacing.md)
            .background(accentColor.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                    .stroke(accentColor, lineWidth: 1)
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

// MARK: - Icon Button

/// 아이콘 버튼 (원형)
public struct SnapIconButton: View {
    let icon: String
    let size: Size
    let style: Style
    let action: () -> Void

    @State private var isPressed = false

    public enum Size {
        case small   // 36pt
        case medium  // 44pt
        case large   // 56pt

        var dimension: CGFloat {
            switch self {
            case .small: 36
            case .medium: 44
            case .large: 56
            }
        }

        var iconSize: CGFloat {
            switch self {
            case .small: 14
            case .medium: 18
            case .large: 24
            }
        }
    }

    public enum Style {
        case filled(Color)
        case outlined(Color)
        case ghost(Color)
    }

    public init(
        icon: String,
        size: Size = .medium,
        style: Style = .ghost(SnapColors.textPrimary),
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.size = size
        self.style = style
        self.action = action
    }

    public var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.buttonTap()
            }
            action()
        } label: {
            Image(systemName: icon)
                .font(.system(size: size.iconSize, weight: .semibold))
                .foregroundStyle(foregroundColor)
                .frame(width: size.dimension, height: size.dimension)
                .background(backgroundColor)
                .clipShape(Circle())
                .overlay(borderOverlay)
                .scaleEffect(isPressed ? 0.9 : 1.0)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        }
        .buttonStyle(.plain)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }

    private var foregroundColor: Color {
        switch style {
        case .filled: SnapColors.background
        case .outlined(let color), .ghost(let color): color
        }
    }

    private var backgroundColor: Color {
        switch style {
        case .filled(let color): color
        case .outlined(let color): color.opacity(0.1)
        case .ghost: .clear
        }
    }

    @ViewBuilder
    private var borderOverlay: some View {
        switch style {
        case .outlined(let color):
            Circle()
                .stroke(color, lineWidth: 1)
        default:
            EmptyView()
        }
    }
}

// MARK: - Toggle Button

/// 토글 버튼
public struct SnapToggleButton: View {
    let title: String
    let icon: String
    @Binding var isOn: Bool

    public init(_ title: String, icon: String, isOn: Binding<Bool>) {
        self.title = title
        self.icon = icon
        self._isOn = isOn
    }

    public var body: some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.toggle()
            }
            isOn.toggle()
        } label: {
            HStack(spacing: SnapSpacing.sm) {
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))

                Text(title)
                    .font(SnapTypography.labelLarge)

                Spacer()

                Image(systemName: isOn ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 20))
                    .foregroundStyle(isOn ? SnapColors.neonLime : SnapColors.textTertiary)
            }
            .foregroundStyle(isOn ? SnapColors.textPrimary : SnapColors.textSecondary)
            .padding(SnapSpacing.md)
            .background(isOn ? SnapColors.neonLime.opacity(0.1) : SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
            .overlay(
                RoundedRectangle(cornerRadius: SnapCornerRadius.md)
                    .stroke(isOn ? SnapColors.neonLime : SnapColors.border, lineWidth: isOn ? 1 : 0.5)
            )
        }
        .buttonStyle(.plain)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isOn)
    }
}

// MARK: - Segmented Control

/// 세그먼트 컨트롤
public struct SnapSegmentedControl<T: Hashable>: View {
    let options: [(value: T, label: String, icon: String?)]
    @Binding var selection: T
    @Namespace private var namespace

    public init(options: [(value: T, label: String, icon: String?)], selection: Binding<T>) {
        self.options = options
        self._selection = selection
    }

    public var body: some View {
        HStack(spacing: SnapSpacing.xs) {
            ForEach(options, id: \.value) { option in
                segmentButton(option)
            }
        }
        .padding(SnapSpacing.xs)
        .background(SnapColors.backgroundElevated)
        .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
    }

    private func segmentButton(_ option: (value: T, label: String, icon: String?)) -> some View {
        Button {
            Task { @MainActor in
                HapticManager.shared.modeSwitch()
            }
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selection = option.value
            }
        } label: {
            HStack(spacing: SnapSpacing.xs) {
                if let icon = option.icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }
                Text(option.label)
                    .font(SnapTypography.labelMedium)
            }
            .foregroundStyle(selection == option.value ? SnapColors.background : SnapColors.textSecondary)
            .padding(.horizontal, SnapSpacing.md)
            .padding(.vertical, SnapSpacing.sm)
            .background {
                if selection == option.value {
                    RoundedRectangle(cornerRadius: SnapCornerRadius.sm)
                        .fill(SnapColors.neonLime)
                        .matchedGeometryEffect(id: "segment", in: namespace)
                }
            }
        }
        .buttonStyle(.plain)
    }
}
