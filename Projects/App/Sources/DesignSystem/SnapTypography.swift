import SwiftUI

// MARK: - Snap Typography System

/// 타이포그래피 시스템
public enum SnapTypography {
    // MARK: - Display (대형 제목)

    /// 대형 제목 (32pt, Bold)
    public static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)

    /// 중형 제목 (28pt, Bold)
    public static let displayMedium = Font.system(size: 28, weight: .bold, design: .rounded)

    /// 소형 제목 (24pt, Semibold)
    public static let displaySmall = Font.system(size: 24, weight: .semibold, design: .rounded)

    // MARK: - Headlines

    /// 헤드라인 대 (20pt, Semibold)
    public static let headlineLarge = Font.system(size: 20, weight: .semibold, design: .rounded)

    /// 헤드라인 중 (17pt, Semibold)
    public static let headlineMedium = Font.system(size: 17, weight: .semibold, design: .rounded)

    /// 헤드라인 소 (15pt, Semibold)
    public static let headlineSmall = Font.system(size: 15, weight: .semibold, design: .rounded)

    // MARK: - Body

    /// 본문 대 (17pt, Regular)
    public static let bodyLarge = Font.system(size: 17, weight: .regular, design: .default)

    /// 본문 중 (15pt, Regular)
    public static let bodyMedium = Font.system(size: 15, weight: .regular, design: .default)

    /// 본문 소 (13pt, Regular)
    public static let bodySmall = Font.system(size: 13, weight: .regular, design: .default)

    // MARK: - Labels

    /// 레이블 대 (14pt, Medium)
    public static let labelLarge = Font.system(size: 14, weight: .medium, design: .default)

    /// 레이블 중 (12pt, Medium)
    public static let labelMedium = Font.system(size: 12, weight: .medium, design: .default)

    /// 레이블 소 (11pt, Medium)
    public static let labelSmall = Font.system(size: 11, weight: .medium, design: .default)

    // MARK: - Caption

    /// 캡션 (10pt, Regular)
    public static let caption = Font.system(size: 10, weight: .regular, design: .default)

    // MARK: - Monospace (숫자, 코드)

    /// 모노스페이스 대 (17pt)
    public static let monoLarge = Font.system(size: 17, weight: .medium, design: .monospaced)

    /// 모노스페이스 중 (15pt)
    public static let monoMedium = Font.system(size: 15, weight: .medium, design: .monospaced)

    /// 모노스페이스 소 (13pt)
    public static let monoSmall = Font.system(size: 13, weight: .medium, design: .monospaced)
}

// MARK: - Text Style Modifiers

extension View {
    /// 제목 스타일 적용
    func snapTitle() -> some View {
        self
            .font(SnapTypography.headlineLarge)
            .foregroundStyle(SnapColors.textPrimary)
    }

    /// 본문 스타일 적용
    func snapBody() -> some View {
        self
            .font(SnapTypography.bodyMedium)
            .foregroundStyle(SnapColors.textSecondary)
    }

    /// 레이블 스타일 적용
    func snapLabel() -> some View {
        self
            .font(SnapTypography.labelMedium)
            .foregroundStyle(SnapColors.textTertiary)
    }

    /// 캡션 스타일 적용
    func snapCaption() -> some View {
        self
            .font(SnapTypography.caption)
            .foregroundStyle(SnapColors.textTertiary)
    }
}
