import Shared
import SwiftUI

/// A shared, accessible action treatment for setup and utility screens.
public struct SnapActionButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    public func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(SnapTypography.headlineSmall)
            .foregroundStyle(isEnabled ? SnapColors.accent : SnapColors.textDisabled)
            .padding(.horizontal, SnapSpacing.lg)
            .frame(minHeight: 48)
            .frame(maxWidth: .infinity)
            .background(SnapColors.accent.opacity(isEnabled ? 0.12 : 0.04))
            .clipShape(RoundedRectangle(cornerRadius: SnapCornerRadius.md))
            .opacity(configuration.isPressed ? 0.7 : 1)
            .animation(reduceMotion ? nil : .easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

public struct SnapSecondaryButton: View {
    let title: String
    let icon: String?
    let accentColor: Color
    let action: () -> Void

    public init(
        _ title: String,
        icon: String? = nil,
        accentColor: Color = SnapColors.accent,
        action: @escaping () -> Void
    ) {
        self.title = title
        self.icon = icon
        self.accentColor = accentColor
        self.action = action
    }

    public var body: some View {
        Button {
            Task { @MainActor in HapticManager.shared.buttonTap() }
            action()
        } label: {
            HStack(spacing: SnapSpacing.sm) {
                if let icon { Image(systemName: icon) }
                Text(title).multilineTextAlignment(.center)
            }
        }
        .buttonStyle(SnapActionButtonStyle())
        .accentColor(accentColor)
    }
}
