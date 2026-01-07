import SwiftUI

// MARK: - Snap Design System Colors

/// Deep Dark Mode 컬러 시스템 (OLED 최적화)
public enum SnapColors {
    // MARK: - Background Colors (Deep Dark)

    /// 순수 검정 배경 (OLED 최적화)
    public static let background = Color.black

    /// 약간 밝은 배경 (카드, 시트)
    public static let backgroundElevated = Color(white: 0.08)

    /// 더 밝은 배경 (입력 필드, 선택된 항목)
    public static let backgroundTertiary = Color(white: 0.12)

    /// 호버/프레스 상태 배경
    public static let backgroundHighlight = Color(white: 0.16)

    // MARK: - Neon Accent Colors

    /// 라임 그린 (Primary Accent)
    public static let neonLime = Color(red: 0.75, green: 1.0, blue: 0.0)

    /// 사이버 블루 (Secondary Accent)
    public static let cyberBlue = Color(red: 0.0, green: 0.9, blue: 1.0)

    /// 네온 핑크 (Tertiary Accent)
    public static let neonPink = Color(red: 1.0, green: 0.2, blue: 0.6)

    /// 네온 오렌지 (Warning)
    public static let neonOrange = Color(red: 1.0, green: 0.6, blue: 0.0)

    /// 네온 레드 (Error/Destructive)
    public static let neonRed = Color(red: 1.0, green: 0.25, blue: 0.25)

    // MARK: - Text Colors

    /// 기본 텍스트 (흰색)
    public static let textPrimary = Color.white

    /// 보조 텍스트 (밝은 회색)
    public static let textSecondary = Color(white: 0.7)

    /// 비활성 텍스트 (어두운 회색)
    public static let textTertiary = Color(white: 0.45)

    /// 비활성화된 텍스트
    public static let textDisabled = Color(white: 0.3)

    // MARK: - System Color Aliases (시스템 색상 대체용)

    /// systemBackground 대체
    public static let systemBackground = background

    /// secondarySystemBackground 대체
    public static let secondarySystemBackground = backgroundElevated

    /// tertiarySystemBackground 대체
    public static let tertiarySystemBackground = backgroundTertiary

    /// tertiarySystemFill 대체
    public static let tertiarySystemFill = backgroundHighlight

    /// label 대체
    public static let label = textPrimary

    /// secondaryLabel 대체
    public static let secondaryLabel = textSecondary

    /// tertiaryLabel 대체
    public static let tertiaryLabel = textTertiary

    /// separator 대체
    public static let separator = Color(white: 0.2)

    // MARK: - Border & Divider

    /// 기본 테두리
    public static let border = Color(white: 0.2)

    /// 강조 테두리
    public static let borderHighlight = Color(white: 0.3)

    /// 구분선
    public static let divider = Color(white: 0.15)

    // MARK: - Connection Status Colors

    /// 연결됨 (Neon Lime)
    public static let statusConnected = neonLime

    /// 연결 중 (Neon Orange)
    public static let statusConnecting = neonOrange

    /// 검색 중 (Cyber Blue)
    public static let statusDiscovering = cyberBlue

    /// 연결 끊김 (Neon Red)
    public static let statusDisconnected = neonRed

    // MARK: - Semantic Colors (상태별 고정 색상)

    /// 녹음 중 상태 (빨강)
    public static let recording = Color.red

    /// 파괴적 액션 (삭제 등)
    public static let destructive = Color.red

    /// 경고 상태
    public static let warning = Color.orange

    /// 성공 상태
    public static let success = Color.green

    /// 레이저 포인터 (빨강 고정 - 실제 레이저 포인터 색상)
    public static let laserPointer = Color.red

    // MARK: - Gradient Presets

    /// 네온 그라데이션 (Lime → Blue)
    public static let gradientNeon = LinearGradient(
        colors: [neonLime, cyberBlue],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 네온 핑크 그라데이션
    public static let gradientPink = LinearGradient(
        colors: [neonPink, neonOrange],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// 다크 그라데이션 (카드 배경용)
    public static let gradientDark = LinearGradient(
        colors: [backgroundElevated, background],
        startPoint: .top,
        endPoint: .bottom
    )

    // MARK: - Glow Effects

    /// 네온 라임 글로우
    public static func glowLime(radius: CGFloat = 10) -> some View {
        neonLime.opacity(0.5).blur(radius: radius)
    }

    /// 사이버 블루 글로우
    public static func glowBlue(radius: CGFloat = 10) -> some View {
        cyberBlue.opacity(0.5).blur(radius: radius)
    }
}

// MARK: - Color Extension

extension Color {
    /// 네온 글로우 효과가 적용된 색상
    func withGlow(radius: CGFloat = 8, opacity: Double = 0.6) -> some View {
        ZStack {
            self.opacity(opacity).blur(radius: radius)
            self
        }
    }
}

// MARK: - View Modifier for Neon Border

struct NeonBorderModifier: ViewModifier {
    let color: Color
    let cornerRadius: CGFloat
    let lineWidth: CGFloat
    let glowRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color, lineWidth: lineWidth)
            )
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(color.opacity(0.5), lineWidth: lineWidth * 2)
                    .blur(radius: glowRadius)
            )
    }
}

extension View {
    /// 네온 테두리 효과 적용
    func neonBorder(
        color: Color = SnapColors.neonLime,
        cornerRadius: CGFloat = 12,
        lineWidth: CGFloat = 1,
        glowRadius: CGFloat = 4
    ) -> some View {
        modifier(NeonBorderModifier(
            color: color,
            cornerRadius: cornerRadius,
            lineWidth: lineWidth,
            glowRadius: glowRadius
        ))
    }
}
