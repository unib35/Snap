import SwiftUI

// MARK: - Connection Blur Modifier

/// 연결 끊김 시 블러 효과
struct ConnectionBlurModifier: ViewModifier {
    let isDisconnected: Bool
    let message: String

    func body(content: Content) -> some View {
        content
            .blur(radius: isDisconnected ? 8 : 0)
            .overlay {
                if isDisconnected {
                    disconnectedOverlay
                }
            }
            .animation(.easeInOut(duration: 0.3), value: isDisconnected)
    }

    private var disconnectedOverlay: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()

            VStack(spacing: SnapSpacing.lg) {
                ZStack {
                    Circle()
                        .fill(SnapColors.neonRed.opacity(0.15))
                        .frame(width: 80, height: 80)

                    Image(systemName: "wifi.slash")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(SnapColors.neonRed)
                }

                Text(message)
                    .font(SnapTypography.headlineMedium)
                    .foregroundStyle(SnapColors.textPrimary)
                    .multilineTextAlignment(.center)

                Text("Mac에 다시 연결해주세요")
                    .font(SnapTypography.bodyMedium)
                    .foregroundStyle(SnapColors.textSecondary)
            }
            .padding(SnapSpacing.xxl)
        }
        .transition(.opacity)
    }
}

extension View {
    /// 연결 끊김 시 블러 효과 적용
    func connectionBlur(isDisconnected: Bool, message: String = "연결이 끊어졌습니다") -> some View {
        modifier(ConnectionBlurModifier(isDisconnected: isDisconnected, message: message))
    }
}

// MARK: - Press Effect Modifier

/// 버튼 프레스 효과
struct PressEffectModifier: ViewModifier {
    @State private var isPressed = false
    let scale: CGFloat
    let opacity: CGFloat

    init(scale: CGFloat = 0.96, opacity: CGFloat = 0.8) {
        self.scale = scale
        self.opacity = opacity
    }

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? scale : 1.0)
            .opacity(isPressed ? opacity : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
            .simultaneousGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in isPressed = true }
                    .onEnded { _ in isPressed = false }
            )
    }
}

extension View {
    /// 프레스 효과 적용
    func pressEffect(scale: CGFloat = 0.96, opacity: CGFloat = 0.8) -> some View {
        modifier(PressEffectModifier(scale: scale, opacity: opacity))
    }
}

// MARK: - Glow Animation Modifier

/// 네온 글로우 애니메이션
struct GlowAnimationModifier: ViewModifier {
    let color: Color
    let isActive: Bool

    @State private var glowOpacity: Double = 0.3

    func body(content: Content) -> some View {
        content
            .shadow(color: color.opacity(isActive ? glowOpacity : 0), radius: 12, x: 0, y: 0)
            .shadow(color: color.opacity(isActive ? glowOpacity * 0.5 : 0), radius: 24, x: 0, y: 0)
            .onAppear {
                if isActive {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.6
                    }
                }
            }
            .onChange(of: isActive) { _, newValue in
                if newValue {
                    withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                        glowOpacity = 0.6
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        glowOpacity = 0.3
                    }
                }
            }
    }
}

extension View {
    /// 네온 글로우 애니메이션 적용
    func glowAnimation(color: Color = SnapColors.neonLime, isActive: Bool = true) -> some View {
        modifier(GlowAnimationModifier(color: color, isActive: isActive))
    }
}

// MARK: - Shimmer Effect

/// 시머 효과 (로딩)
struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        .clear,
                        SnapColors.textPrimary.opacity(0.1),
                        .clear
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = 400
                }
            }
    }
}

extension View {
    /// 시머 효과 적용
    func shimmer() -> some View {
        modifier(ShimmerModifier())
    }
}

// MARK: - Card Style Modifier

/// 카드 스타일 적용
struct CardStyleModifier: ViewModifier {
    let cornerRadius: CGFloat
    let hasBorder: Bool

    func body(content: Content) -> some View {
        content
            .background(SnapColors.backgroundElevated)
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            .overlay {
                if hasBorder {
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(SnapColors.border, lineWidth: 0.5)
                }
            }
    }
}

extension View {
    /// 카드 스타일 적용
    func cardStyle(cornerRadius: CGFloat = SnapCornerRadius.lg, hasBorder: Bool = true) -> some View {
        modifier(CardStyleModifier(cornerRadius: cornerRadius, hasBorder: hasBorder))
    }
}
