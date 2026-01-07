import SwiftUI

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
